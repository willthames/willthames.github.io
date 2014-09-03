---
title: Techniques for Versioning Ansible
date: 2014-08-11 20:56:00
layout: post
---
First, let's start with the why. With source control and inventory, do we actually need 
to version Ansible playbooks or roles? 

In an environment with multiple development teams with their own requirements, we want
to ensure that different teams don't trample on each others toes. 

Repeatability is key - running the same playbook months apart against the same environment
should have exactly the same result. 

The problem we wish to solve is when updating a playbook or role, 
how do we ensure that later redeployments, in particular to production,
(for example when autoscaling) don't pick up those changes. 

<div class="alert alert-warning"><span class="glyphicon glyphicon-warning-sign"></span> The information from here on in, while a possible solution, has been
superseded by <a href="/2014/09/03/techniques-for-versioning-ansible-ii.html">later events</a>
</div>

Using a suitable version control workflow (such as separate branches for develop and mainline)
would be one technique of ensuring that the correct version of a playbook was run against the
appropriate environment &mdash; but you still need a way of tying branch to environment. 

Alternatively, as long as you store the commit id for each playbook per environment,
you can redeploy at will. Storing a commit id in 
version control is annoying (as you have to do the commit, find out the id, and then add that
to inventory in a subsequent commit), but you could tag the commit and reference the tag.

However, a separate problem is common roles, where more than one playbook is using a common role, and 
someone wishes to improve one of those common roles. At that point you want to ensure that
playbooks choose to be updated to use the newer role version, and not have that imposed upon
later redeployments of older playbooks. When the playbook is being updated for its own changes,
it still may not necessarily wish to bring in the changes of the updated role, and commit ids
and tags have no (obvious) solution for this scenario. 

From here on in, I describe the approach that is starting to solve the problem with the
constraints we have. I don't claim it to be perfect, and I'm sure plenty of people have 
different thoughts.

On this basis, we are just using directory naming for role versioning, combined with a number
of rules.

### Roles contain the version in their name

In the roles subdirectory (either inside a playbook directory or in the `roles_path` directory)
roles are stored in `rolename/roleversion` directories

{% highlight yaml %}
ansible-playbooks/application
 - templates
 - vars
 - playbooks
     - playbook.yml
     - roles
         - helloworld
             - 0.0.1
                 - tasks
                 - meta
                 - vars
                 - templates
             - 0.0.2
         - anotherrole
             - 1.2.3
{% endhighlight %}

### Playbooks do not vary
This one at first glance seems extreme, but all of the logic can be removed from a playbook
and moved into roles

{% highlight yaml %}
{% raw %}
- hosts: application-{{env}}
  vars_files: 
  - ../inventory/group_vars/application-{{env}}.yml

  roles:
  - application/{{application_role_version}}
{% endraw %}
{% endhighlight %}

Unfortunately we have to include the environment inventory vars file (containing
`application_role_version` explicitly. This is because `application_role_version` 
cannot come implicitly from inventory (what roles get included 
gets calculated before inventory is read). Also, you'll need to pass in `-e env=test`.

Once the playbook is in such a minimal state, with all the logic and variables moved completely
out of the playbook, we can hope that it needs no further changes. 

### One role per playbook

There's no need to include multiple roles in the playbook when the main role can
include all the dependent roles. So for an application that relies on installing java
and tomcat, `meta/main.yml` might look like:

{% highlight yaml %}
dependencies:
- { role: java7/1.0.0, minor_version: 65 }
- { role: tomcat/2.3.1, tomcat_version: "7.0.55" }
{% endhighlight %}

To make the main benefit of this, it's worth setting `role_path` in your Ansible configuration
file to the path to common roles. 

### Roles should have status metadata

Role versions should transition through a lifecycle. They start off in `DRAFT` status (when changes
should be expected by any playbooks that use them). From there they transition to `FINAL` 
where no changes are allowed except to change the status to `DEPRECATED` as they get
superseded. Status names could be improved (for example `BETA` or `DEVEL` rather than `DRAFT`, 
`SUPERSEDED` rather than `DEPRECATED` and perhaps `FINAL` isn't so final if it can be superseded.)

{% highlight yaml %}
# Status: DRAFT
---
dependencies:
- { role: amazing/0.0.1 }
{% endhighlight %}

Checks can then be made to warn when a playbook is using draft or deprecated roles, and version
control hooks could be used to enforce the lifecycle constraints. 

At most one version per role should be in `FINAL` status.

### Updating roles

When improving a role (consider the role `amazing` at version 0.0.1 referenced above, 
several things happen:

* Basically the latest role version is first copied wholesale `cp -a amazing/0.0.1 amazing/0.0.2`
* Update `amazing/0.0.2/meta/main.yml` to set status to `DRAFT`
* Update whatever needs to be changed to reference the new role - if it's another role rather
  than inventory feeding a playbook, then that role will need to go through the same process
* Test the new role
* Once the role is ready for production, update `amazing/0.0.1` to have status `DEPRECATED` and
  set `amazing/0.0.2` to have status `FINAL`
