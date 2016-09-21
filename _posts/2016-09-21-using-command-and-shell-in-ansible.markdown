---
title: Using Ansible's command and shell modules properly
date: 2016-09-21 11:01:00
layout: post
---
I realise I have quite strong opinions on the `command` and
`shell` modules in Ansible. There are now four independent checks in
[ansible-lint](https://github.com/willthames/ansible-lint) for ways to
use the modules badly. Let me count the ways...

### Using command/shell instead of a better module

There are a number of modules that can be used instead of commands.
Obvious candidates include most package installation modules
(`yum`, `rpm`, `pip`, etc.), most version control modules (`git`,
`hg`, etc.), OS control modules such as `service`.

There are also commands that can be run when an argument to the
`file` module would be better - e.g `file state=absent` rather
than `rm`, `file state=link` rather than `ln`.

I also managed
to introduce a [`command_warnings` check](http://docs.ansible.com/ansible/intro_configuration.html#command-warnings)
into Ansible that will warn you at runtime.

With the following playbook:

```
- hosts: target
  gather_facts: no

  tasks:
  - name: get coreutils version
    command: rpm -q coreutils
```

`ansible-playbook` outputs a warning when `command_warnings` is enabled:

```
$ ansible-playbook playbook.yml

PLAY [target] ******************************************************************

TASK [get coreutils version] ***************************************************
changed: [target]
 [WARNING]: Consider using yum, dnf or zypper module rather than running rpm

PLAY RECAP *********************************************************************
target                     : ok=1    changed=1    unreachable=0    failed=0
```

Because of the great potential for false positives (e.g. you
need to run a command that has a module in a way that the module
does not support), it's easy to switch off warnings in a way
that works with both `ansible` and `ansible-lint` - just add
`warn: no` to the command arguments

```
- name: get coreutils version
  command: rpm -q coreutils
  args:
    warn: no
  register: coreutils_version
```

(Using non-YAML notation, the middle three lines would just be
`command: warn=no rpm -q coreutils`, but I've moved over to full
YAML form in my playbooks now - and I have an `ansible-review`
check for that! For simplicity I use the key-value form in inline
examples here.)

### Using shell instead of command

The `shell` module is potentially more dangerous than the `command`
module (ok, nothing is really stopping you doing `command: rm -rf --no-preserve-root`)
and should only be used when you actually need shell functionality.
So if you're not stringing two commands together (using pipes or
even just `&&` or `;`), you don't really need the `shell` module.
Similarly, expanding shell variables or file globs require the
`shell` module. If you're not using these features, don't use
the `shell` module. If you are using these features, think twice
if you can rewrite the `shell` command to make it more Ansibley.

### Convergence and command/shell

When you run `command` or `shell`, they always set `changed` to `True`.
This is because Ansible has no mechanism for understanding whether
your command changed anything or not. Some commands are genuinely
read only (e.g. `git status`) and others have side effects. 

Generally, one expects with Ansible that when a playbook is run
twice, no changes should happen on the second run. There are
(at least) four ways to achieve this (`ansible-lint` only checks
these four, so if there's another mechanism, let me know).

#### 1. changed_when

If a command is read only, set `changed_when` to `False`. If you
can tell whether a command changed something based on its return
code or its stdout or stderr, you can use this with `changed_when`:

```
- name: clear yum cache
  command: yum clear metadata
  register: yum_clear
  changed_when: '"\n0 metadata files removed" not in yum_clear.stdout'
```

#### 2. and 3. creates and removes

If a command creates a file after it is first run, or removes a file
after it is first run, you can use the `creates` or `removes` argument
with `command` or `shell`. Then it won't run a second time.

```
- name: trivially create a file
  shell: echo "hello" > /tmp/hello
  args:
    creates: /tmp/hello
```

(don't use the above example, use `copy: content=hello dest=/tmp/hello`)

#### 4. when

Often a command behaves from the outside world no differently if it
puts something into a state or it's already in that state. In such
cases, it might always return a 0 exit status, and print no output.

In these cases, you might need a read-only pre-check command that
determines whether the system is already in the desired state, and
then not do the changing task if it is.

```
- name: check tuned profile
  command: tuned-adm active
  register: tuned_adm
  changed_when: False

- name: set tuned profile
  command: tuned-adm profile virtual-guest
  when: "'Current active profile: virtual-guest' not in tuned-adm.stdout"
```
