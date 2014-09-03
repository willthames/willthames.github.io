---
title: Techniques for Versioning Ansible II
date: 2014-09-03 20:30:00
layout: post
---
This is a replacement post for my most recent entry on 
[techniques for versioning ansible](/2014/08/11/techniques-for-versioning-ansible.html).
The motivations described within that post remain valid.
We do versioning for the following reasons:

* Allow the reuse of a role across multiple playbooks
* Ensure playbooks to have the same effect, even when run months later
* Roles may be updated without worrying about breaking earlier
  playbooks that rely on them

Even while writing the post I thought that source control versioning 
should be part of the solution but I didn't have an easy
way to include roles with a specific tag or branch in a playbook.

When publicising the post, a [better approach was discussed](https://groups.google.com/d/msg/ansible-project/TawjChwaV08/N04ukdTsrwMJ), 
and after a lot of further discussion and some tweaks to the
Ansible source code, the solution was [coded](https://github.com/ansible/ansible/pull/8600) and [announced](https://groups.google.com/d/msg/ansible-project/RMa1tp1N1JY/O9Sw0I6CvbwJ)!

[Ansible Galaxy](http://galaxy.ansible.com/) has long been a source 
of community roles to provide certain capabilities ready for reuse.
However, they mostly rely on certain (often valid) assumptions - that
you have root privilege, you can install RPMs or your OS equivalent, 
that your ansible control host (or target host) can talk to the internet, etc.
If you are working outside of those assumptions then your organisation
might require its own common roles. Until very recently there was no
standard way of doing this. 

The `ansible-galaxy` command line tool has now been updated to allow
the installation of roles from an arbitrary git or mercurial repository
(extending it to other source control systems shouldn't be too hard)
or straight from a (possibly gzipped) tar archive.

## Writing roles

Roles can be created using `ansible-galaxy init rolename` and 
then filling in the `README.md` as well as the
`meta/main.yml` specification file. The
spec file can use the same role declarations in the dependencies 
section - so if the `tomcat` role relied on an `java` role you 
might have the following in `meta/main.yml`

```
...
dependencies:
- role: git+http://git.internal/galaxy/role-java.git,v1.0,java
```

Once the role is ready, you can then publish the role to whatever
repository suits your needs. Once tested, you can tag the role,
e.g.

```
git tag v1.0
git push origin v1.0
```

## Using roles in playbooks

To specify what roles you would like to use in your playbook, you can
specify a roles file and then use 
`ansible-galaxy install -r rolesfile -p roles` to install it under the
`roles` directory. A roles file might look like:

```
git+http://git.internal/galaxy/tomcat.git,v1.0
hg+http://hg.example.com/roles/awkward-name,,nice-name
```

The first installs `v1.0` of a role from a git repository and derives
the name `tomcat`, the second installs the latest version of a role 
from a mercurial repository and renames it `nice-name`.

A YAML equivalent also exists - see [the ansible-galaxy docs](http://docs.ansible.com/galaxy.html#the-ansible-galaxy-command-line-tool) for more details.

At this point then, you're effectively just putting a specific version
of a role inside your repository. This is not dissimilar to how Go
source code ensures that the appropriate versions of a library are
associated with the code. 

In our organisation we put in a couple of principles for versioning of roles:

* All roles that are ready to go to production should be tagged with a version
* All playbooks that are ready for production should specify which versions of each role to use

You could use [git submodules](http://git-scm.com/book/en/Git-Tools-Submodules)
(or presumably a mercurial equivalent) rather than installing the roles 
alongside the playbook but we're keeping it simple for now.

## Versioning playbooks

Again, tags and changesets are useful to identify a version of a playbook
to use when deploying to an environment (of course you still need some
way of knowing exactly what version of a playbook *should* be used with
which environment). 

One way of doing this is to store the version of the playbook with 
the environment. So for a `helloworld` application, `helloworld.yml` might
contain `playbook: helloworld/playbooks/setup.yml`, 
and `helloworld-prod.yml` might contain `playbook_version: v1.2.3`.

This information could then be used to generate a deployment playbook or
feed into e.g. AWS user-data that then kicks off an ansible-pull script.
