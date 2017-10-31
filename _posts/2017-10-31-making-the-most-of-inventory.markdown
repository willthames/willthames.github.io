When using Ansible to consume APIs such as cloud services, the
logic runs from the controller machine. As a result, people tend
to think that as this runs locally, using `hosts: localhost` is
the best option.

In reality, using `localhost` as your host loses you a lot of power.
To avoid this, I use what I call a 'runner' pattern, where a runner
is a local target on which you can hang inventory.

In our environment we tend to be either managing whole environments
(e.g. provisioning an entire network) and infrastructure components
within them (load balancers, database servies) or specific applications.

For environments, we might have a hierarchy that looks a little like:

```
[non_prod_account:children]
dev
test

[dev:children]
dev-runner

[test:children]
test-runner

[runner:children]
dev-runner
test-runner
```

or, in picture form:

![test-runner](/images/test-runner.png)

{% raw %}
That way, when we use `hosts: test-runner` we can pick up all the
inventory associated with the `test` group - the CIDR prefix of networks,
the tag to use for `Environment`, DNS zones, and many many other things
(in reality a lot of our variables come from the `all` group but with
the `env` property used in populating variables - so our VPC name
is `{{ env }}-{{ cidr_prefix }}`.
{% endraw %}

To avoid needing to add `connection: local` to plays using runners,
create a `runner` group vars file (e.g. `inventory/group_vars/runners`)
and add `ansible_connection: local`.

With applications, and the right inventory structure, we can do things
like create all the loadbalancers with:

```
{% raw %}
- hosts: application:&{{ env }}:&runner
  connection: local

  roles:
  - loadbalancer
{% endraw %}
```

Each `application` group contains a (possibly empty) list of loadbalancers,
each item in the list containing the configuration used when calling
something like `elb_application_lb` module.

![application-web-test-runner](/images/application-web-test-runner.png)

Using the runner pattern allows us to avoid a whole bunch of variable files,
and structure inventory in a logical hierarchical fashion, making use of
inheritance to minimise repetition of data.

One disadvantage of the runner pattern is that it creates a ridiculous
combinatorial explosion of hosts and groups in inventory files. In my
next post, I'll show a very simple solution to that.

Oh, and [ansible-inventory-grapher](https://github.com/willthames/ansible-inventory-grapher)
is currently working reasonably well against Ansible 2.4 at last (I need
to tidy some magic variables from the host before it's totally ready for
release, but it's on the ansible-2.4 branch if you're keen)
