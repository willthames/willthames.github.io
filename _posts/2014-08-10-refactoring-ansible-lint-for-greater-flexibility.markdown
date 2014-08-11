---
title: Refactoring ansible-lint for greater flexibility
date: 2014-08-10 17:36:00
layout: post
---
I first wrote [ansible-lint](http://github.com/willthames/ansible-lint) nearly a year ago.
The aim behind my implementation was to be able to spot common antipatterns and indeed bugs
and report them to users. 

I've had a few contributions to ansible-lint, particularly in the last few months, that 
have increased its capability but I'm running into more and more limitations. 

Currently the design is that the rules are a type of `AnsibleLintRule`, and for each playbook
and role various matching functions are performed such as `matchtask` and `matchline`. It is 
then up to the rule to implement suitable behaviour for those matching functions.

When thinking about new rules, I keep coming up with behaviours that would require more and
more of the matching functions. New rules I have in mind are:

* Does an included role have a Status comment in its `meta/main.yml`
* For an included role, are there more than one version of the role with Status set to FINAL
* Does the playbook contain any logic other than roles

My plan for addressing this is to add a new `match` task to `AnsibleLintRule`, and pass it 
a model of the entire Playbook - all the roles it includes, the tasks, handlers, pre_tasks, vars
etc. We can still use `matchline` (which is handy for the rare case where we do line by line matching,
if only because it's the only task that actually returns a line number location!)

I do plan to talk further about versioning in Ansible and some of the rules that I plan to 
develop will help me implement those practices - if other people see the practices as beneficial
then I will likely make them more widely available.

One of the standards we're looking at is that role versions should not be hardcoded in a playbook
(this is so that new role versions can be tested in testing environments while allowing 
redeployments of production on older role versions). This means that running ansible-lint against
such a playbook will also require a hostname (to determine the appropriate role version) or
the role version to be set, or we just examine all possible role versions (i.e. treat the parameter
as a wildcard).
