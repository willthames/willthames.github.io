---
title: Ansible slow to startup on Fedora 23
date: 2016-03-11 16:05:00
layout: post
---
I was sitting with a colleague helping with some Ansible stuff and I couldn't
help noticing his playbook runs were taking a minute before the first
connection to a host.

This is not normal. Even in a reasonable size environment with a few hundred
hosts in inventory, startup times are typically of the order of a few seconds.

So we did some straceing.

```
strace -r -o /tmp/strace.out ansible -m debug -a 'msg=hello' testhost
```

was enough to gather some information. Comparing my colleague's results with
my own, I found a lot of 100ms calls to `read`:

```
0.132407 read(7, "/usr/lib/python2.7/site-packages"..., 4096) = 284
```

For a while I wondered why what on first glance was a directory read was
taking so long, when I wasn't even seeing the `read` on my computer at all. And
then I spotted the truncation (the `...`). So we repeated the strace with
`-s 300` (we only needed 284 bytes from the result of the `read`)

And then we found the actual problem:

```
read(7, "/usr/lib/python2.7/site-packages/keyring/backends/Gnome.py:6:
PyGIWarning: GnomeKeyring was imported without specifying a version first. Use
gi.require_version('GnomeKeyring', '1.0') before import to ensure that the right
version gets loaded.\n  from gi.repository import GnomeKeyring\n", 4096) = 284
```

As my colleague doesn't actually use gnome keyring, a `yum erase python-keyring`
sufficed.

There is a [bug](https://bugzilla.redhat.com/show_bug.cgi?id=1259747)
against python-keyring in Fedora 23 which also has a workaround in the second
comment if you do need to use it.
