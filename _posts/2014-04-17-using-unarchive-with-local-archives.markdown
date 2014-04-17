---
title: Using unarchive with local archives
date: 2014-04-17 11:25
layout: post
categories: tips
---
Ansible's [unarchive module](http://docs.ansible.com/unarchive_module.html) has been around a while but 
it's not always been suitable for use on archives local to the destination node (especially when running
ansible-playbook on the destination host using the local connection. There are two key elements to this tip: 
<div class="alert alert-info"><span class="glyphicon glyphicon-info-sign"></span> Use <code>copy=no</code> to ensure that no attempt is made to copy the archive from the host running ansible to the destination node
</div><p></p>

<div class="alert alert-warning"><span class="glyphicon glyphicon-warning-sign"></span> <code>dest</code> must end in a slash! This is because it uses pythons <code>os.path.dirname</code> to check if the directory is
writable - if you have write access to say /usr/local, and use <code>dest=/usr/local</code>, it will actually check 
whether you have write access to /usr, and fail if you don't. So use <code>dest=/usr/local/</code>
</div>

{% highlight text %}
- hosts: localhost
  connection: local

  tasks:
  - name: download artefact from website
    get_url: url="http://www.example.com/downloads/archive.tgz" dest="/tmp/archive.tgz"

  - name: extract artefact under /usr/local
    unarchive: copy=no src="/tmp/archive.tgz" dest="/usr/local/"
{% endhighlight %}
