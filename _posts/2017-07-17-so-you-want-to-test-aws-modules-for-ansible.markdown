You're a (prospective) contributor to Ansible, and you have some
great improvements to make to an existing module or a brand new
module. As a conscientious developer, you know that having tests
will ensure that you don't break existing behaviour, and that other
people's future enhancements won't break your desired behaviour.
The standard tests for AWS modules are integration tests as most
of them rely on creating some resources in AWS, updating them, and
then cleaning up afterwards.

I'll start this post from absolute first principles - I'll use
a shiny new Fedora 26 vagrant VM.


## Setting up Ansible for development

```
vagrant init fedora/26-cloud-base
vagrant up
vagrant ssh
```

The easiest way to ensure we have all the dependencies for Ansible
installed is then to use `dnf` to install ansible.

```
sudo dnf install ansible
```

Next, clone the your fork of the source code for ansible:

```
ssh-keygen
eval `ssh-agent -s`
ssh-add
# Add the generated key to your github account
sudo dnf install git
git clone git@github.com:YOURUSER/ansible
cd ansible
git remote add upstream https://github.com/ansible/ansible
git pull upstream devel
```

Note that if you're doing this on a host with any other ssh keys,
it's worth generating a github specific ssh key (using e.g.
`ssh-keygen -f ~/.ssh/github`) and setting up
your .ssh/config appropriately:

```
Host github.com
  IdentityFile ~/.ssh/github
```

At this point, `ansible --version` should give the released version of
Ansible (at the time of writing, this was 2.3.1.0). To use the development
version (not recommended for production use), do:

```
source hacking/env-setup
```

And `ansible --version` should now show the development version (currently
2.4.0)

## Install docker

Add docker and set it up so that you don't have to be root to run it. There
are some security implications with this - being in the docker group is
[effectively equivalent to root access](https://docs.docker.com/engine/security/security/#docker-daemon-attack-surface).

```
sudo dnf install docker
sudo groupadd docker
sudo gpasswd -a $USER docker
sudo systemctl restart docker
newgrp docker
```


## Setting up AWS account

Install the relevant command line tools (you can do this in a virtualenv
if you prefer - it depends if you'd need to test with different versions
of boto3 etc). The boto library is currently still required for quite a
few modules, as well as the common code used to connect to AWS.

```
pip install --user botocore boto3 boto awscli
```

Ensure you have an IAM administrative user with API access. DO NOT
use this user for Ansible, or put its credentials anywhere near your
git repo! I use boto profiles for all of the AWS accounts that I use,
and don't have a default profile so that I always have to choose.

Note: DO NOT use your AWS root user - if you don't have a suitable
user yet, create a new IAM user with
the AdministratorAccess managed policy (or similar) attached

Ensure a [profile for this IAM user](http://boto3.readthedocs.io/en/latest/guide/configuration.html)
exists in ~/.aws/credentials and then run:

```
export ADMIN_PROFILE=$your_profile_name
ansible-playbook hacking/aws_config/setup-iam.yml -e iam_group=ansible_test -e profile=$ADMIN_PROFILE -e region=us-east-2 -vv
```

You don't actually have to set profile or region at all if you don't need
them - region defaults to `us-east-1`, but you can only choose `us-east-2`
as an alternative at this time.

You'll now need to go into AWS console, create an IAM user (called e.g. `ansible_test`)
and make them a member of
the newly created group (`ansible_test` if you used that with `iam_group` in
While you're there, create an API credential for the test user.
This can all be automated:

```
aws iam create-user --user-name ansible_test --profile $ADMIN_PROFILE
aws iam add-user-to-group --user-name ansible_test --group_name ansible_test --profile $ADMIN_PROFILE
aws iam create-access-key --user-name ansible_test --profile $ADMIN_PROFILE
```

Note: This can be done through Ansible's [iam module](docs.ansible.com/ansible/iam_module.html)
too. It's just simpler to document the steps with the CLI as they fit on three lines
rather than one very long `ansible` adhoc command line or a larger ansible playbook.

Using the information from the new credential, you can do:

```
cp test/integration/cloud-config-aws.yml.template test/integration/cloud-config-aws.yml
```

and then update that file to include this new secret key and access key.
It's also worth adding the following for `region` if you're not using us-east-1

```
{% raw %}
aws_region: us-east-2
ec2_region: "{{ aws_region }}"
{% endraw %}
```

Note: The credentials in ~/.aws/credentials and cloud-config-aws.yml should be
completely different. A good way to test this is:

```
aws sts get-caller-identity --profile=$ADMIN_PROFILE
```

```
{% raw %}
ansible -m shell -a 'AWS_SECRET_ACCESS_KEY={{ aws_secret_key }} AWS_ACCESS_KEY_ID={{ aws_access_key }} aws sts get-caller-identity' \
  -e @test/integration/cloud-config-aws.yml localhost
{% endraw %}
```

The first of these should return your administrator user. The second of these
should return your Ansible test user. If this isn't the case, check the previous
steps (and let me know if I can improve the documentation!).

## Running an integration test suite

Check that you can run the integration tests

```
ansible-test integration --docker -v ec2_group
```

The first run will be quite slow as you need to pull down all the required containers.
Future runs will be much quicker, particularly if you pass `--docker-no-pull` to
speed things up (it's worth updating the containers fairly regularly, of course)

## Writing your own tests

For your module, you will need:

* `test/integration/module_name/aliases`
* `test/integration/module_name/meta/main.yml`
* `test/integration/module_name/tasks/main.yml`

### meta/main.yml

```
- dependencies:
  - prepare_tests
  - setup_ec2
```

These are needed to ensure that `resource_prefix` is available to your tests.
All resources are expected to be prefixed with this to ensure that they can
be cleaned up more easily.

### aliases

```
cloud/aws
posix/ci/cloud/aws
```

Without the aliases file, the cloud-config-aws.yml doesn't get picked up.

### tasks/main.yml

This should contain all of the tasks needed for the tests. Most actions are
coupled with an `assert` task that the test has had the desired effect.

The main tasks should be in a `block` with an accompanying `always` that
cleans up to avoid things being left behind by the tests

```
{% raw %}
- block:
  - name: create resource
    aws_module:
      state: present
      name: "{{ resource_prefix }}-more-name"
      ...
    register: aws_module_result

  - name: check that resource was created
    assert:
      that:
        - aws_module_result.changed
        - aws_module_result.name == "{{ resource_prefix }}-more-name"
    ...

- always:
  - name: remove resource
    aws_module:
      state: absent
      name: "{{ resource_prefix }}-more-name"
      ...
{% endraw %}
```


Things worth checking
* Create a resource, assert that the returned properties are as expected
* Run that task again, check that nothing changed
* Update a resource, check that the returned properties are changed
* Run that task again, check that nothing changed
* If the task has `purge_tags` or similar, check that works as expected
* Run the task again in check mode
* Delete the resource

## Troubleshooting

While docker is quite useful for quickly running tests and cleaning up after
itself, occasionally you might need to get the debugger out to see why
your module isn't doing what you expect.

At this point, it's likely easiest to create a quick test playbook

```
- hosts: localhost
  vars_files:
  - test/integration/cloud-config-aws.yml

  roles:
  - test/integration/targets/aws_module
```

And run this with `ANSIBLE_KEEP_REMOTE_FILES=1 ansible-playbook test-playbook.yml -vvv`.
You can then follow the [ansible debugging instructions](https://docs.ansible.com/ansible/dev_guide/developing_modules_best_practices.html#debugging-ansiblemodule-based-modules).

I tend to use `epdb` to put in a breakpoint where the module is going wrong (or before the
module has gone wrong) and analyse from there.

So my steps are:

1. `python /path/to/module explode`
2. `cd /path/to/debug_dir`
3. Edit `ansible_module_module_name.py`, add `import epdb; epdb.st()` at the relevant location
4. `python /path/to/module execute`
5. `python -c 'import epdb; epdb.connect()'`

## Tidy up

Detach the policies from your test IAM group - this will leave the test group and user in
place but with zero privileges.

```
export GROUP=$your_iam_group
for policy_arn in `aws iam list-attached-group-policies --group-name $GROUP --profile $ADMIN_PROFILE --query 'AttachedPolicies[].PolicyArn' --output text`
do aws iam detach-group-policy --group-name $GROUP --policy-arn $policy_arn --profile $ADMIN_PROFILE
done
```

Shut down docker and vagrant

```
sudo systemctl stop docker
exit
vagrant halt
```

## Conclusion

This post is designed to assist people with setting up the various steps needed to test
and debug AWS modules for Ansible. There are almost certainly errors, omissions, and
things that *I* could learn to do better. 

If you have any suggestions for improvement, please raise an issue or PR
on https://github.com/willthames/willthames.github.io or just let me know on Twitter or email (links below). Thanks!

## Thanks

Thanks to Moritz Grimm for pointing out a couple of typos. These are now fixed.
