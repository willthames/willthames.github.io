---
title: A Worked Example of Role Versioning
date: 2015-04-03 11:00:00
layout: post
---
This post is an example of how to use versioning of roles with playbooks.
The initial premises are these:

* We have per-environment playbooks. This is not very DRY but allows
  us to maintain different versions of applications in different
  environments
* The bulk of the logic is in roles - our playbooks have almost zero
  logic in them
* Roles are versioned rather than playbooks
* Roles MUST be versioned before being used in production
* Production environments MUST specify explicit role versions (not HEAD)

Roles are versioned using git tagging, and these versions are specified
in the roles specification files (rolesfile) associated with a playbook.

I've created two example git repositories - to follow along, perform the
following somewhere:

```
git clone https://github.com/willthames/playbook-versioning-example.git
git clone https://github.com/willthames/role-versioning-example.git
```

### First deployment

In the first iteration, we want to get the role ready to deploy to
production. The directory structure for the playbook looks like this:

```
.
├── inventory
│   ├── example
│   └── group_vars
│       ├── prod.yml
│       └── stage.yml
└── stage
    ├── rolesfile
    └── stage-playbook.yml
```

We don't need to specify a version until we think it's ready for
production, and so the rolesfile is just:

```
git+https://github.com/willthames/role-versioning-example.git
```

To install the role alongside the playbook, we can use the following:

```
ansible-galaxy install -r stage/rolesfile -p stage/roles
```

which uses `stage/rolesfile` to specify the roles to install under
`stage/roles`.

We can now run the playbook:

```
$ ansible-playbook stage/stage-playbook.yml

PLAY [stage] ******************************************************************

GATHERING FACTS ***************************************************************
ok: [stage01]

TASK: [role-versioning-example | do something] ********************************
ok: [stage01] => {
    "msg": "Welcome to 1.0 in environment stage"
}

PLAY RECAP ********************************************************************
localhost                  : ok=2    changed=0    unreachable=0    failed=0
```

This is ready to promote. So we'll tag the role, update the stage rolesfile
to reference the version, retest and then create the playbook for production

```
$ cd path/to/role
$ git tag v1.0
$ git push origin v1.0
$ cd path/to/playbooks
$ vi stage/rolesfile # add ,v1.0 to the end
$ ansible-galaxy install --force -r stage/rolesfile -p stage/roles
$ ansible-playbook stage/stage-playbook.yml
```

We can then create the playbook and rolesfile for prod and we're
ready to deploy to prod:

```
$ ansible-galaxy install --force -r prod/rolesfile -p prod/roles
$ ansible-playbook prod/prod-playbook.yml
```

At this point stage and prod look pretty much the same, except the
message says it's the prod environment:

```
$ ansible-playbook prod/prod-playbook.yml

PLAY [prod] *******************************************************************

GATHERING FACTS ***************************************************************
ok: [prod01]

TASK: [role-versioning-example | do something] ********************************
ok: [prod01] => {
    "msg": "Welcome to 1.0 in environment prod"
}

PLAY RECAP ********************************************************************
prod01                     : ok=2    changed=0    unreachable=0    failed=0
```

### Upgrading

Let's say  a new version of the application is required, and we want to test
in staging while still being able to maintain the production
environment in case of the need to build a new production server.

At this point, we can edit the stage rolesfile to point to HEAD again
(i.e. remove the version component), update the role and test out
version 1.1

```
$ ansible-playbook stage/stage-playbook.yml

PLAY [stage] ******************************************************************

GATHERING FACTS ***************************************************************
ok: [stage01]

TASK: [role-versioning-example | Print a nice message] ************************
ok: [stage01] => {
    "msg": "Welcome to 1.1 in environment stage"
}

PLAY RECAP ********************************************************************
stage01                    : ok=2    changed=0    unreachable=0    failed=0
```

As we're happy with the 1.1 changes, we can tag the role with `v1.1`,
push the tag and update stage's rolefile and retest.

Until we're ready to release to production, we have deployments to stage
using the new version (1.1) and production still good for any emergency
redeploys of 1.0.

```
$ ansible-playbook prod/prod-playbook.yml

PLAY [prod] *******************************************************************

GATHERING FACTS ***************************************************************
ok: [prod01]

TASK: [role-versioning-example | do something] ********************************
ok: [prod01] => {
    "msg": "Welcome to 1.0 in environment prod"
}

PLAY RECAP ********************************************************************
prod01                     : ok=2    changed=0    unreachable=0    failed=0
```

I hope this example is clear enough, please let me have any feedback via
twitter or as issues in either of the github repos.
