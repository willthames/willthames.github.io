---
title: Debugging Ansible for fun and no profit
date: 2014-04-28 15:19
layout: post
---
A colleague reported some strange behaviour regarding Ansible, in particular with `pgrep` and `pkill` in the shell module.

A simple test case is
{% highlight text %}
- hosts: localhost
  connection: local

  tasks:
  - name: show bad effects of pgrep
    action: shell pgrep -f bobbins || true
{% endhighlight %}

Running this with `ansible-playbook pgrepdemo.yml -v`
