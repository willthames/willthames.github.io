---
title: An Introduction to Code Reviews
date: 2016-11-07 11:30:00
layout: post
---
Most software development teams have long been doing code reviews, and
while it's not uncommon amongst system administrators, 
it's not universally practised.

## Why do code reviews

Constructive code reviews are a means of ensuring the quality
of code is consistent across the team &ndash;
and typically all code gets raised to a much higher standard as a result.
Through code reviews, junior team members can see obtain feedback from
their peers on their contributions before merge, as well as learn
from the feedback on other colleagues' contributions. But code review
is not just for the benefit of junior team members &ndash; it promotes
a shared understanding of the entire codebase amongst the team,
making it easier for everyone to contribute. Additionally it
provides visibility of changes to the codebase to everyone, which
helps to avoid errors, and reduce wasteful or overly complicated
code being added to the codebase.

## When should code reviews happen

Code reviews should happen before any commit gets merged into
a production codebase. Sometimes this principle needs to be
bypassed (e.g. an emergency fix for production when no reviewer
is available) but such changes should be still be reviewed
retrospectively.

Ideally, code would undergo some kind of continuous integration
testing prior to review. The sophistication of such testing
can range from basic syntax checking up to full-scale test deployments.
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

## For the Reviewer: Reviewing the code

First of all, you have to understand the change you're reviewing.
If you don't understand the change, you can't positively review
the change. A good commit message should contain the purpose of
the change, and if necessary, how that change is being achieved.
If, after reading the commit messages, you don't understand what
is going on, you should ask for the commit message to be improved.

When you understand the change, there are a few key levels of
code review:

- syntax &ndash; is the code well formatted, meeting indentation and
  whitespace standards and free from parse errors.
- style &ndash; is the code idiomatic for the language, are common
  error-prone patterns for that language avoided, is the code
  easily understood
- functional &ndash; does the code do what it's supposed to do
- architecture &ndash; is the code required, are there any improvements
  to be made through abstractions, reuse of other code. Does the
  code tie in with the rest of the codebase.

The first two of these are excellent candidates for automated checks &ndash;
particularly as from a reviewer's point of view, they're really
tedious to review, and from a reviewee's point of view, they can feel
like nitpicking. If the code has to meet such automated
checks before it even gets to review, then the human element
can be saved for the deep structural thought.
[`ansible-review`](/2016/06/28/announcing-ansible-review.html) is
an example of such a tool for Ansible; most languages and CM
frameworks have similar tools.

Comment on specific lines of code if you can to say where the
code doesn't meet standards or could be improved. General feedback
on the change as a whole can typically be provided as a comment
without referencing a specific line.

Assume best intentions, and try and address the code rather than
the person writing the code. Criticism should never be personal.

Code reviews should be objective where possible. There are always
subjective preferences in any code base, but such preferences should
be decided at a team level beforehand, and then be well documented &ndash;
by pointing to such documentation in the code
review, the feeling of subjectivity can be avoided. As you come
across undocumented preferences, determine that they are what
the team wish to use, and document them.

If you are satisfied that there are no blocking issues with the
change, signify your approval in the appropriate way.

I prefer to let the code contributor accept the change if possible,
in case there are any last minute issues that they notice. In some
tools or under some permission schemes, this may not be allowed,
and others may have to merge the result.

## For the Reviewee: Prepare for code reviews

For a contributor:

- ensure that your [commit messages explain
  what you are trying to achieve and why](http://chris.beams.io/posts/git-commit/).
- adhere to the standards of your code base.
- assume best intentions from the reviewer.
- realise that a code review is not a battle,
  and try not to take criticism of your code personally.
  However, if criticism is personal, then you should say so.
- try and reduce conflict resulting from misunderstandings &ndash;
  see if you can clear up such misunderstandings, either in the review, in the
  commit messages or through talking it through with the reviewer.

## Getting started

If you don't currently do code reviews, and you're not using pull
requests for contributing code, and you don't have documented
standards, all of the above might seem a little daunting.

Not having standards is a bit of a chicken and egg situation &ndash;
without reviewing code, often preferences exist but aren't
expressed anywhere (some of our preferences have been implicit
for years until a new contributor comes along and does something
off the wall, and we realise it needs to be explicit).

One way to start might be to just ask a colleague to give you
feedback on your recent commits. This might help to start
discovering preferences, and then these can be documented.
From there, you'll likely find that code review tools provide
a much easier way to provide feedback, because you can associate
your comments with a line of code very easily.

In our global team of 20+ sysadmins, we actually use a code
review process for improving our standards
and best practices &ndash; all new standards must be accepted by at least
two colleagues, and all best practice suggestions must get at least
one +1. This is intended to ensure that no one feels that standards
are imposed upon them. In a small
co-located team a 2 minute chat might suffice instead!
