---
title: "connection: local vs delegate_to: localhost"
---
Performing tasks locally is a common operation when working with an API of some
kind&mdash;typical use cases are cloud services, network devices, cluster
management. There are three ways of achieving this in Ansible: `connection:
local`, `delegate_to: localhost` and `local_action`. The last is rarely seen these
days and can be deemed equivalent to `delegate_to: localhost` in terms of
advantages and disadvantages, but with the additional disadvantage of being
a very unusual style, adding a readability penalty.

In a previous post I talked about the
[runner pattern](http://willthames.github.io/2017/10/31/making-the-most-of-inventory.html)
which allows better use of inventory for different scenarios even when the
controller is localhost. `connection: local` behaves very differently
if the host is `localhost` or a 'runner' host, which is surprising.

The main difference between `connection` and `delegate_to` is that connection can
be used at a play or task level, whereas `delegate_to` operates at a task level
only. This means that if you have a playbook with fifty tasks, each will need
`delegate_to` set. Worse, if you're using someone else's role, you'll have to
hope they've provided for this eventuality.

The problem with `connection: local` for the runner pattern is that it assumes
that it's an entirely new connection and will use the system python rather than
what ever python you prefer to use. Situations where this is a problem include
when using `virtualenv`s to install python libraries or on OS X where most rely
on python from brew. In this case, you might run `pip install library`, run
Ansible and find that that library can't be found because it's looking in the
wrong place.

To demonstrate this, I wrote a [`boto3_facts` module](https://github.com/ansible/ansible/pull/42083),
which shows python location and version as well as boto3 and botocore versions.

```
- hosts: localhost
  gather_facts: no

  tasks:
  - name: localhost without explicit connection
    boto3_facts:

- hosts: fakehost
  gather_facts: no

  tasks:
  - name: runner host using delegate_to
    boto3_facts:
    delegate_to: localhost

- hosts: fakehost
  gather_facts: no

  tasks:
  - name: runner host using local_action
    local_action:
      module: boto3_facts

- hosts: fakehost
  connection: local
  gather_facts: no

  tasks:
  - name: runner host using local connection
    boto3_facts:
```

```
$ ansible-playbook boto3_facts.yml -v -i fakehost,
Using /Users/will/tmp/ansible/boto3_facts/ansible.cfg as config file

PLAY [localhost] *****************************************************************************************************************

TASK [localhost without explicit connection] *************************************************************************************
ok: [localhost] => changed=false
  boto3_version: 1.7.42
  botocore_version: 1.10.42
  python: /usr/local/Cellar/python@2/2.7.14_3/Frameworks/Python.framework/Versions/2.7/Resources/Python.app/Contents/MacOS/Python
  python_version: |-
    2.7.14 (default, Mar  9 2018, 23:57:12)
    [GCC 4.2.1 Compatible Apple LLVM 9.0.0 (clang-900.0.39.2)]

PLAY [fakehost] ******************************************************************************************************************

TASK [runner host using delegate_to] *********************************************************************************************
ok: [fakehost -> localhost] => changed=false
  boto3_version: 1.7.42
  botocore_version: 1.10.42
  python: /usr/local/Cellar/python@2/2.7.14_3/Frameworks/Python.framework/Versions/2.7/Resources/Python.app/Contents/MacOS/Python
  python_version: |-
    2.7.14 (default, Mar  9 2018, 23:57:12)
    [GCC 4.2.1 Compatible Apple LLVM 9.0.0 (clang-900.0.39.2)]

PLAY [fakehost] ******************************************************************************************************************

TASK [runner host using local_action] ********************************************************************************************
ok: [fakehost -> localhost] => changed=false
  boto3_version: 1.7.42
  botocore_version: 1.10.42
  python: /usr/local/Cellar/python@2/2.7.14_3/Frameworks/Python.framework/Versions/2.7/Resources/Python.app/Contents/MacOS/Python
  python_version: |-
    2.7.14 (default, Mar  9 2018, 23:57:12)
    [GCC 4.2.1 Compatible Apple LLVM 9.0.0 (clang-900.0.39.2)]

PLAY [fakehost] ******************************************************************************************************************

TASK [runner host using local connection] ****************************************************************************************
ok: [fakehost] => changed=false
  python: /usr/bin/python
  python_version: |-
    2.7.10 (default, Oct  6 2017, 22:29:07)
    [GCC 4.2.1 Compatible Apple LLVM 9.0.0 (clang-900.0.31)]

PLAY RECAP ***********************************************************************************************************************
fakehost                   : ok=3    changed=0    unreachable=0    failed=0
localhost                  : ok=1    changed=0    unreachable=0    failed=0
```

{% raw %}
The easiest way to fix this is to set `ansible_python_interpreter: "{{ ansible_playbook_python }}"`.
My preferred approach is in `group_vars/all` if all tasks run locally, or
`group_vars/runner` if using the runner pattern&mdash;but, as with below, at playbook vars
level also works.
{% endraw %}

In conclusion, I much prefer `connection: local` for the runner pattern now that
`ansible_python_interpreter` can be set dynamically.

{% raw %}
```
- hosts: fakehost
  connection: local
  vars:
    ansible_python_interpreter: "{{ ansible_playbook_python }}"
  gather_facts: no

  tasks:
  - name: runner host using local connection and ansible_python_interpreter set
    boto3_facts:
```
{% endraw %}

```
PLAY [fakehost] ******************************************************************************************************************

TASK [runner host using local connection and ansible_python_interpreter set] *****************************************************
ok: [fakehost] => changed=false
  boto3_version: 1.7.42
  botocore_version: 1.10.42
  python: /usr/local/Cellar/python@2/2.7.14_3/Frameworks/Python.framework/Versions/2.7/Resources/Python.app/Contents/MacOS/Python
  python_version: |-
    2.7.14 (default, Mar  9 2018, 23:57:12)
    [GCC 4.2.1 Compatible Apple LLVM 9.0.0 (clang-900.0.39.2)]
```
