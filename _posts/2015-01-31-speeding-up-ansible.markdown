---
title: Speeding up Ansible
date: 2015-01-31 11:00:00
layout: post
---
I noticed at work recently that Ansible seemed to be taking a really long
time. On further inspection of the start and end time of tasks, each task
seemed to be taking three seconds.

This isn't a parallelisation problem - this was on a single host. And when
you have hundreds of tasks scattered across various roles, and their
dependencies, included by a single playbook, then you have a problem.

My first step was to add further instrumentation into the `runner` part
of Ansible, the bit that actually executes the commands on the remote machines.

Once I'd instrumented it reasonably, tasks were broken down into
about 3 seconds of transfer, and up to a second of execution. Ouch. 

## Control Persist
ControlPersist is turned on by default for everyone using the `ssh`
connection method to Ansible (which has been the default for a good 
while), if their ssh installation supports it. This is not the case
for unpatched RHEL distributions (it was added as part of a 
[Security Advisory](https://rhn.redhat.com/errata/RHSA-2014-1552.html) 
in October 2014). If you can't use ControlPersist, you'll need to 
use paramiko, which is quicker than ssh without ControlPersist.

To see the details of your ssh connection, use ansible-playbook with
the `-vvv` option. You should see `-o ControlPersist=60s`, among
other ssh options.

Using an AWS server in US East (about 250ms ping time from Brisbane),
we see a speed up of a simple ssh command of nearly 10x
```
[will@cheetah ansible-tests (master)]$ time ssh -o ControlMaster=auto -o ControlPersist=60s -o ControlPath=/tmp/ansible-ssh-%h-%p-%r ec2-54-152-69-19.compute-1.amazonaws.com echo hello
hello

real  0m5.815s
user  0m0.008s
sys 0m0.006s
[will@cheetah ansible-tests (master)]$ time ssh -o ControlMaster=auto -o ControlPersist=60s -o ControlPath=/tmp/ansible-ssh-%h-%p-%r ec2-54-152-69-19.compute-1.amazonaws.com echo hello
hello

real  0m0.729s
user  0m0.003s
sys 0m0.003s
```

## Pipelining
Ansible recently introduced pipelined command execution, where the transfer
and execution of the Ansible module happens in the same ssh connection.
Tests at work (again, from Brisbane to US East but to private servers)
suggest a speed up from 3 seconds to 1 second to run a simple command.
My tests with AWS often fail with pipelining switched off, and are still
quite slow switched on, so I need to improve that!

To enable pipelining, add:

```
[ssh_connection]
pipelining = True
```

to your Ansible configuration file
