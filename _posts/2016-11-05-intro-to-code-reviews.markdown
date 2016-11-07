---
title: An Introduction to Code Reviews
date: 2016-11-05 07:30:00
layout: post
draft: true
---
Most software development teams have long been doing code reviews, and
it's definitely not uncommon amongst systems administrators, but neither
is it universally practised.

## Why do code reviews

Code reviews are a means of ensuring a team-level quality of code &ndash;
hopefully all code gets brought to a much higher standard as a result.
Through code reviews, junior team members can see obtain feedback from
their peers on their contributions before merge, as well as learn
from the feedback on other colleagues' contributions. But code review
is not just for the benefit of junior team members &ndash; it promotes
a shared understanding of the entire codebase amongst the team,
which should help eliminate wasteful code being added to the codebase.
Often obvious errors can be avoided before they get into the
codebase at all (non-obvious errors will hopefully get found at a
pre-production testing phase)

## When should code reviews happen

Code reviews should happen before any commit gets merged into
a production codebase. Sometimes this principle needs to be
bypassed (e.g. an emergency fix for production when no reviewer
is available) but such changes should be still be reviewed
retrospectively.

Ideally, code would undergo some kind of continuous integration
testing prior to review. The sophistication of such testing
can be basic syntax checking up to full-scale test deployments.
If it passes this automated checking, then it's worth spending
human effort on a review.

## Where do code reviews happen

Most social version control platforms (Github, Bitbucket, etc.)
have the ability to do
Pull Requests (or Merge Requests in Gitlab's case). This is the
easiest (but not necessarily most robust) way to have them.

Dedicated code review platforms such as Gerrit, Crucible may
also be used &ndash; it doesn't really matter what tool you
use as long as you are able to comment at the line level, at
the general level, and provide some indicator of approval
(e.g. a +1 or shipit)

Refer to the documentation for your version control platform,
and perhaps your internal documentation for your change
workflow, for how to submit reviews.

## What should people look for in a code review

First of all, you have to understand the change you're reviewing.
If you don't understand the change, you can't positively review
the change. A good commit message should contain the purpose of
the change, and if necessary, how that change is being achieved.
If, after reading the commit messages, you don't understand what
is going on, you should ask for the commit message to be improved.

When you understand the change, there are a few key levels of
code review:

- syntax &ndash; is the code well formatted, meeting indentation and
  whitespace standards. Is it idiomatic for the language
- semantics &ndash; are common error-prone patterns avoided
- functional &ndash; does the code do what it's supposed to do
- architecture &ndash; is the code required, are there any improvements
  to be made through abstractions, reuse of other code. Does the
  code tie in with the rest of the codebase.

The first two of these are excellent candidates for automated checks &ndash;
particularly as from a reviewer's point of view, they're really
tedious to review, and from a reviewee's point of view, they just
seem like tedious nitpicking. If the code has to meet such automated
checks before it even gets to review, then the human element
can be saved for the deep structural thought.

## Reviewing the code

Comment on specific lines of code if you can to say where the
code doesn't meet standards or could be improved. General feedback
on the change as a whole can typically be provided as a comment
without referencing a specific line.

Code reviews should be objective where possible. There are always
subjective preferences in any code base, but such preferences should
be well documented &ndash; by pointing to such documentation in the code
review, the feeling of subjectivity can be avoided. As you come
across undocumented preferences, document them.

Assume best intentions, and try and address the code rather than
the person writing the code. Criticism should never be personal.

If you are satisfied that there are no blocking issues with the
change, signify your approval in the appropriate way.

I prefer to let the code submitter accept the change if possible,
in case there are any last minute issues that they notice. In some
tools or under some permission schemes, this may not be allowed,
and others may have to merge the result.

## How should someone best prepare for the code review

For a contributor, ensure that your [commit messages explain
what you are trying to achieve and why](http://chris.beams.io/posts/git-commit/).
Adhere to the standards
of your code base. Realise that code reviews shouldn't be a battle,
and try not to take criticism of your code personally. Assume best
intentions from the reviewer. However, if criticism
is personal, then you should say so. A lot of conflict in code
reviews comes from misunderstandings &ndash; try and see if you
can clear up such misunderstandings &ndash; either in the review, in the
commit messages or just through personal interaction (face to face,
by phone or through online means)
