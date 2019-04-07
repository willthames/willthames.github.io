---
title: Using updated modules, libraries and plugins with stable Ansible
date: 2017-12-12 10:00:00
layout: post
---
<div class="alert alert-info"><span class="glyphicon glyphicon-info-sign"></span>
This page was updated on 2019-04-07 to improve `module_utils` information and
add plugin information</div>

There are many reasons to want to use newer modules than a chosen
stable Ansible core release:

* Feature enhancements don't get backported to stable branches
* Non-security bug fixes only tend to get backported one version &mdash;
  which means if say 2.N.0 hasn't had all the core bugs ironed out yet,
  you might not get the benefit of module bug fixes while you remain on
  2.N-1.0
* Some improvements only exist in PR form. Some improvements only exist
  in branches made by combining multiple PRs.<sup>&dagger;</sup> Some improvements are very
  handy but so experimental they're not even ready for a PR!<sup>&dagger;</sup>

When that happens, thankfully you don't have to run off your own megamerge
branch of ansible<sup>&dagger;</sup>. 

My approach for this is to use the [default `library`
directory](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#default-module-path)
feature &mdash;
create a `library` directory in the top level of your playbooks repository,
and put any modules that you need but aren't yet in the version of ansible
you're using there.

I also keep a README.md file in the library directory. It looks a bit like:

```
|Module                     | PR                                            | Notes           |
|---------------------------|-----------------------------------------------|-----------------|
|cloudfront_distribution.py | https://github.com/ansible/ansible/pull/31284 | Unmerged        |
|ec2_placement_group.py     | https://github.com/ansible/ansible/pull/33139 | Available in 2.5|
```

Keeping track of why I'm using each module allows me to remove released modules after each major or minor Ansible release.

If you're using modules that rely on updates to `module_utils` shared libraries, you can  set
the [`module_utils` config directive](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#default-module-utils-path)
in ansible.cfg (`./module_utils` is an undocumented default) and copy the relevant `module_utils` files into your codebase as well.
The layout of your `module_utils`
directory should reflect that of ansible. For example, if you need updates to the `k8s` module, you'll probably
need to copy one or both of `k8s/common.py` and `k8s/raw.py` from `lib/ansible/module_utils` to your
`module_utils/k8s` directory. You will also need an empty `__init__.py` at the bottom level directory.

```
module_utils/
└── k8s
    ├── __init__.py
    ├── common.py
    └── raw.py
```

Similarly, you can optionally set [`filter_plugins`](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#default-filter-plugin-path),
(which has `./filter_plugins`as an undocumented default),
[`lookup_plugins`](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#default-lookup-plugin-path)
(which has `./lookup_plugins` as an undocumented default),
etc. to point to updated plugins &mdash; I tend to use `plugins/lookup`, `plugins/filter` etc. to reflect Ansible's codebase structure (but
I didn't know about the defaults until doing some tests for the update to this page).

One other point worth noting is that if you're already using roles for your logic, you can put updates of modules, libraries
and plugins in your `library`, `module_utils` and `plugins` directories at the top level of the role.
You'll need a versioning strategy for your role that reflects Ansible versions so that you can remove published changes
later on (for example my [Kubernetes role](https://github.com/willthames/ansible-role-kube-resource)
has a v2.8 branch without the `module_utils/k8s` tree) with published `v2.7-1` and `v2.8-1` tags. The need for an `__init__.py` doesn't
seem to be as apparent when using a role (i.e. my tests pass on my Kubernetes-role without needing an `__init__.py`)

<sup>&dagger;</sup> &mdash; I've been there.
