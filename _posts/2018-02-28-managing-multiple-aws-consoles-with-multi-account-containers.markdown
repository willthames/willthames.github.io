---
title: Managing Multiple AWS Consoles With Multi Account Containers
---
While there are ways of managing multiple AWS account consoles in a single browser
(such as assuming roles to access other accounts), various constraints might prevent that
(e.g. accounts owned by third parties to which access should be segregated).

Most people in this situation have done the 'browser juggle', where you might have
Firefox open with another window in Safe mode, Chrome open with another window in
Incognito mode, and no doubt further browsers depending upon your OS.

With Firefox's [Multi Account Container add-on](https://addons.mozilla.org/en-US/firefox/addon/multi-account-containers/)
this can be a thing of the past. This add on makes it easy to manage multiple AWS
accounts in a single Firefox window.

First, set up a container per account by clicking the Multi Account Container button, usually
to the right end of the add ons bar, (or pressing `<Ctrl>-.`)
and then Edit Containers. Give each account a separate colour if possible (as the colour
appears as a line under the tab title, making it easier to distinguish which tab corresponds
to which account).

Each time you need to use the console in a different account, long-click the `+` new tab
button (also available via File &gt; New Container Tab and, I've
[just learned](https://github.com/mozilla/multi-account-containers/issues/119#issuecomment-355050735),
`<Ctrl>+.` and then `<Tab>` to select through the containers)

You'll still to need to log in to the appropriate account for the container in the normal way.
Even if you close all the container tabs, and later reopen the console in that same container,
it'll remember your session&mdash;so you'll be back in the console as long as your session hasn't
expired.

Note that you can also elect to always open a URL in a particular container (not so useful for multiple
AWS consoles, useful for segregating off sites whose business model depends on knowing what you're doing,
yes, I mean Facebook&mdash;particularly if you then default all other sites to a new container, or even
just clear all cookies)
