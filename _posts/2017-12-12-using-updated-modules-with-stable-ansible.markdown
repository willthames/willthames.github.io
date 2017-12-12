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
directory](http://docs.ansible.com/ansible/latest/intro_configuration.html#id119)
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

One minor caveat: if the module you're using relies on recent updates to
`module_utils` shared libraries, you might need to either copy those into the module or instead use
the [`module_utils` config directive](http://docs.ansible.com/ansible/latest/intro_configuration.html#module-utils)
in ansible.cfg and copy the relevant `module_utils` file into your codebase as well.

<sup>&dagger;</sup> &mdash; I've been there.
