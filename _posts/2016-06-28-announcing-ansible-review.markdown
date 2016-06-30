---
title: Announcing ansible-review
date: 2016-06-28 06:05:00
layout: post
---
[`ansible-review`](https://github.com/willthames/ansible-review)
is coming up to the three month anniversary of the first commit,
and I've given it little publicity other than an
[ignite talk](http://willthames.github.io/devops-bris-ignite/#/) at the last
[DevOps Brisbane Meetup](http://www.meetup.com/Devops-Brisbane/).

`ansible-review` is a code review tool for Ansible. A lot of the work that was
done in the `ansible-lint` 3.0 release was done to accommodate `ansible-review`,
including some new rules, and some tidy ups that allow better reuse of the
`ansible-lint` code.

I've been working on coding standards for Ansible for around 3 years now.
Following an early version of Alexandra Spillane and Matt Callanan's talk
on [Making the Right Way the Easy Way](https://www.youtube.com/watch?v=yPy44B9h820),
I've been careful to version standards, and ensure that best practices
are advisory, and standards are (at least theoretically) testable.

There are a number of key differences between `ansible-lint` and
`ansible-review`.

### Designed for code review

`ansible-review` can take the result of a `git diff` and only highlight errors on
the changed sections.

```
git diff -U0 | ansible-review
```

reviews only the lines that have changed (if an error is at a file level,
rather than a line level, it will output that if the file has changed at all).

This is on the principle that even if the file as a whole doesn't meet
latest standards, the improvements do.

### Works with versioned checks

If you version your standards, you can ensure that errors only occur for
playbooks and roles that declare a version newer than the standard (if
versions aren't declared, then the tool assumes you want the latest version
of the standards).

`ansible-review` looks for a line starting `# Standards: x.y` in
playbooks and in role's `meta/main.yml`. This declares what version
is being met. Failing checks with versions prior or equal to that
are errors, and failing checks with later versions or no version
are warnings.

This is useful for checks where you might like to know that a playbook
or role could be at risk of bad practices, but not necessarily fail on.

### Works on lots of different Ansible things

`ansible-review` attempts to classify what kind of thing a file is, and
then run the checks specific to that file kind. So inventory host
variables can have different checks to a role's `meta/main.yml`.

### Choose the checks you want

`ansible-review` doesn't even come with default checks (although there is
an [example
`standards.py`](https://github.com/willthames/ansible-review/blob/master/examples/standards.py)
file). Use the checks that work for your organisation.
You might want to introduce all the example checks in your first version
of best practices, or just start with one check in version 0.1 and build up
over time)

## Examples of standards

The `standards.py` file contains an array of `Standard`s. Each `Standard`
has a name, a check, a list of types that the check applies to, and
optionally a version.

Here's an example of a standard that uses an `ansible-lint` check:

```
with_items_bare_words = Standard(dict(
    name="bare words are deprecated for with_items",
    check=lintcheck('ANSIBLE0015'),
    types=["task", "handler", "playbook"]
))
```

That uses rule ANSIBLE0015, and runs against task files (`tasks/main.yml` etc.),
handler files (`handlers/main.yml` etc) and playbooks.

On running this against a tasks file with bare words, you get:

```
{% raw %}WARN: Future standard "bare words are deprecated for with_items" not met:
tasks/main.yml:9: [ANSIBLE0015] Found a bare variable 'mysql_pkgs' used in a 'with_items' loop. You should use the full variable syntax ('{{mysql_pkgs}}'){% endraw %}
```

The check can be an `ansible-lint` rule using the `lintcheck` function, but
can be your own rule. For example, I don't like host_vars at all (in almost
all instances, variables for a host should come from group membership unless
absolutely unique to the host - SSL key/cert, kerberos keytab etc). So I have
a check for that:

```
def host_vars_exist(candidate, settings):
    errors = [Error(None, "Host vars are generally not required")]
    return Result(candidate.path, errors)
```

An `Error` is a line number (or `None` if it applies to the whole file)
and a message. A `Result` is a filename and a possibly empty list of
`Error`s. Because `ansible-review` can run against a section of a file
(e.g. when running from a diff output) and the line numbers are used
to make helpful error messages and also exclude lines from being
considered as errors.

The standard that uses that check is then

```
host_vars_should_not_be_present = Standard(dict(
    name="Host vars should not be present",
    check=host_vars_exist,
    types=["hostvars"]
))
```

Running this gives:

```
WARN: Future standard "Host vars should not be present" not met:
inventory/host_vars/host.example.com.yml:Host vars are generally not required
```


## Ensuring up to date ansible-review and ansible-lint

`standards.py` can contain `ansible_review_min_version` and
`ansible_lint_min_version`. This is to ensure that checks that
you need actually exist (e.g. a new `ansible-lint` rule)


## Disclosure

I work for Red Hat. Red Hat owns Ansible. Other than the relationships that I
had with Ansible prior to acquisition, my work with Ansible is entirely
independent to the Ansible part of the Red Hat organisation
