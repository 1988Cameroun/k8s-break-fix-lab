# 10 · RBAC: 403 Forbidden from the API server

**Level:** hard · **Namespace:** `lab-10`

## The ticket

> `pod-watcher` is a small internal tool that lists the pods in its own namespace and
> reports them to our dashboard. It runs under the `pod-watcher` ServiceAccount, and a
> Role was created for it. It never becomes Ready, and its logs show `HTTP 403`.

## Your goal

- `pod-watcher` can **list pods in `lab-10`** and becomes Ready.

## Rules (least privilege)

- Don't give it more than it needs. It must **not** be able to delete pods, read
  Secrets, or see pods in other namespaces.
- Don't use a ClusterRole/ClusterRoleBinding, and don't use the `default` ServiceAccount.
