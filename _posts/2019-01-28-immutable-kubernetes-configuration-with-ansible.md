---
title: Immutable Kubernetes configuration with Ansible
date: 2019-01-28 10:00:00
layout: post
---
This post touches on a key component of my [Managing Kubernetes is Easy With
Ansible](https://www.ansible.com/managing-kubernetes-is-easy-with-ansible)
talk that I gave at AnsibleFest 2018.
Since giving that talk, I've also solved some of the unforeseen consequences,
and go into further detail here.

There are a number of problems associated with managing configuration (in the
form of configmaps and secrets) through the default mechanism.

* Changes to configmaps or secrets are not picked up by the pods that rely on
  them unless the related deployment is also updated
* Rolling back a deployment to a previous version does not roll back the
  associated configuration

We can solve these problems through immutable configmaps and secrets that are
named based on their contents, such that if the contents change, their name
changes.

The kubectl tool has part of a solution for that, in that you can pass `--append-hash`
when creating a configmap or secret, but only when using `kubectl create`, it's not
useful when applying resource definitions from files. However, this idea was
the inspiration to add an `append_hash` parameter to Ansible's `k8s` module, and
this is part of the solution.

Another part of the solution is the `k8s_config_resource_name` filter plugin, which
takes a configmap definition and returns the full name with the hash added.

At this point we can define dicts of configmaps and secrets, and also refer to
the full resource name in deployments or similar resources.

In inventory we might have something like:

```
{% raw %}
kube_resource_configmaps:
  env: "{{ lookup('template', kube_resource_template_dir + 'env-configmap.yml') | from_yaml }}"
kube_resource_secrets:
  env: "{{ lookup('template', kube_resource_template_dir + 'env-secrets.yml') | from_yaml }}"
{% endraw %}
```

which then gets referenced in the deployment with:

```
{% raw %}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ kube_resource_name }}
  namespace: {{ kube_resource_namespace }}
spec:
  template:
    spec:
      containers:
        - envFrom:
            - configMapRef:
                name: {{ kube_resource_configmaps.env | k8s_config_resource_name }}
            - secretRef:
                name: {{ kube_resource_secrets.env | k8s_config_resource_name }}
{% endraw %}
```

Its best to create
the secrets and configmaps first, as the pods created by the deployment will depend
on them being present to be able to start - then you can use the `wait` functionality
that the `k8s` module gains with Ansible 2.8 to check the pods start correctly.

At this point, we have met our original goals - changing a configmap or secret
will change its name, and so the deployment will change to point to the new name,
so new pods will be created using the new configuration. The replicaset to which
`kubectl rollback deploy` will roll back will contain the old configuration names,
and so rolling back a deployment will also roll back the configuration.

However, my presentation ignores two issues (the first I was aware of but hadn't yet
solved, the second my colleague highlighted as an obstacle to moving to the new
way of working)

* there is no garbage collection of configmaps that were referenced by replicasets
  but are no longer used
* diffs no longer work - because the configmaps and secrets change name, it's hard
  to compare against the previous version of the configmap or secret.

The solution to both is simple to describe, and harder to implement with the current
tools, but possible.

Kubernetes has the concept of resource owners: if a resource that owns another resource
is deleted, the owned resource is also deleted. So pods are owned by replicasets which
are in turn owned by deployments - deleting the deployment removes all replicasets
associated with the deployment, and all pods associated with those replicasets.

We can use this to add owner references to configmaps and secrets - we find the replicaset
associated with the recent deployment, and set that resource as the owner in the
configmap/secret. This means that when replicasets are retired (Kubernetes keeps ten
replicasets by default, but this is configurable with `spec.revisionHistoryLimit`) the
associated configmaps and secrets are also retired.

For diffs, first we lookup the `deployments.kubernetes.io/version` annotation of the
previous deployment and the current deployment. We then have to find all replicasets
(as there's no way to search by annotation, unfortunately) and then select the
previous replicaset and current replicaset using the same annotation.

Adding a new label, such as `configmap_name_prefix`, to our configmaps allows us to
iterate over our `kube_resource_configmaps` dict (the `label_selectors` argument to
`k8s_facts` is useful here), each time looking for all configmaps
with the label of the current configmap, and then finding the configmap with the
owner reference set to the previous replicaset and the configmap owned by the current
replicaset. Exactly the same technique holds for secrets too. Once we've found
the before and after, we can display the differences using the `debug` module
(an explicit `diff` module might be useful).

I've updated the [ansible-role-kube-resource](https://github.com/willthames/ansible-role-kube-resource)
role with this new functionality so that it's easier
to use, it does rely on all resources having `kube_resource_name` and
`kube_resource_namespace` correctly set. All of the owner reference based functionality
relies on replicasets updating when deployments change - so isn't currently useful for
e.g. statefulsets.

In other news on that role, I've now added a molecule test suite, inspired by
Jeff Geerling (@geerlingguy)'s talk at AnsibleFest and his super helpful
[molecule blog post](https://www.jeffgeerling.com/blog/2018/testing-your-ansible-roles-molecule).
It relies on an existing kubernetes platform being set up and configured, but given
that Docker comes with Kubernetes (on some platforms at least), and that minikube exists,
that shouldn't be insurmountable.

There are quite a few features from Ansible 2.8 that are used in the role but
have been backported into the role - kubernetes resource validation, waiting for resources
to meet the desired state, `append_hash` and `k8s_config_resource_name` for example.
Even if you choose not to use the role, you can make use of the same techniques through
setting and using `module_utils` and `filter_plugins` configuration directives in ansible.cfg.

