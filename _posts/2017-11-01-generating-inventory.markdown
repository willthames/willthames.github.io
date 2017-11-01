As mentioned in [yesterday's blogpost](/2017/10/31/making-the-most-of-inventory.html),
using a combination of environments, applications and operations can cause a cartesian
explosion in hosts and groups to manage.

Even 10 applications in 3 environments over 2 operations can lead to sixty hosts, plus
likely as many groups.

For example, we use a structure that looks like:

```
[environment:children]
application-environment

[application-environment:children]
operation-application-environment

[operation-application:children]
operation-application-environment

[operation-application-environment]
operation-application-environment-runner

[runner]
operation-application-environment-runner

[application:children]
application-environment
operation-application

[operation:children]
operation-application
```


And that's just one host! Admittedly using groups that will be reused many times.

![op-app-env](/images/op-app-env.png)

This problem has always been solvable using a script to generate inventory, but Ansible
2.4's inventory plugin architecture, combined with the inspiration from the
[constructed plugin](https://docs.ansible.com/ansible/devel/plugins/inventory/constructed.html)
caused me to simplify my problem through creating a
[generator plugin](https://github.com/willthames/ansible/blob/generator_inventory_plugin/lib/ansible/plugins/inventory/generator.py).
If the plugin proves popular I'll likely raise a PR soon.

The generator plugin is then installed by putting it into our ansible
playbooks repo under plugins/inventory/generator.py, and updating ansible.cfg to
include

```
[defaults]
inventory_plugins = plugins/inventory

[inventory]
enable_plugins = generator,host_list,script,yaml,ini
```

The above inventory can be expressed with the inventory plugin using:

```
{% raw %}
# inventory.config file in YAML format
plugin: generator
strict: False
hosts:
    name: "{{ operation }}-{{ application }}-{{ environment }}-runner"
    parents:
      - name: "{{ operation }}-{{ application }}-{{ environment }}"
        parents:
          - name: "{{ operation }}-{{ application }}"
            parents:
              - name: "{{ operation }}"
              - name: "{{ application }}"
          - name: "{{ application }}-{{ environment }}"
            parents:
              - name: "{{ application }}"
              - name: "{{ environment }}"
      - name: runner
layers:
    operation:
        - build
        - launch
    environment:
        - dev
        - test
        - prod
    application:
        - web
        - api
{% endraw %}
```

![launch-web-test-runner](/images/launch-web-test-runner.png)

We are already using this to reduce 100+ line static inventory host files (our
biggest as-yet unreduced file is 500 lines!) to something very similar to the above.

The major benefit is, as always, reducing repetition - expanding this to more environments
or applications is then a matter of adding a single element to the appropriate layer,
rather than adding the appropriate groups and hosts in 10 different places.

ansible-inventory-grapher copes fine with the results (I put the effort in to
finally fixing it so that I could validate the result)

```
ansible-inventory-grapher -i inventory/generator.config all -a 'rankdir=LR;' -q | dot -Tpng | display png:-
```

![all](/images/all.png)
