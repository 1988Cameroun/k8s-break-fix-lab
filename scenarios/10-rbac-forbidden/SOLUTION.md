# Solution 10 · RBAC: 403 Forbidden from the API server

## Root cause

The ServiceAccount was correctly bound to the `pod-reader` Role, but the Role only
allowed the `get` verb on pods. `get` reads **one pod by name**
(`GET /api/v1/namespaces/lab-10/pods/<name>`). The app calls the **collection**
endpoint (`GET /api/v1/namespaces/lab-10/pods`), which is the `list` verb. RBAC is
deny-by-default, so the API server returned 403.

## How to diagnose it

```bash
kubectl -n lab-10 logs deploy/pod-watcher
# ERROR: HTTP 403 listing pods: "message":"pods is forbidden: User
#   \"system:serviceaccount:lab-10:pod-watcher\" cannot list resource \"pods\"
#   in API group \"\" in the namespace \"lab-10\""

# Reproduce it yourself without touching the pod:
kubectl auth can-i list pods -n lab-10 --as=system:serviceaccount:lab-10:pod-watcher
# no
kubectl auth can-i get pods -n lab-10 --as=system:serviceaccount:lab-10:pod-watcher
# yes

# See everything the SA can do in the namespace:
kubectl auth can-i --list -n lab-10 --as=system:serviceaccount:lab-10:pod-watcher

# Check what is bound to what:
kubectl -n lab-10 get rolebinding pod-watcher-reads-pods -o wide
kubectl -n lab-10 describe role pod-reader
```

The 403 message names all four parts: **subject** (who), **verb**, **resource +
API group**, and **namespace**. Read each one; any of them can be the mismatch.

## The fix

```bash
kubectl -n lab-10 patch role pod-reader --type=json -p \
  '[{"op":"replace","path":"/rules/0/verbs","value":["get","list"]}]'
```

Add `watch` too if the app uses watches (most controllers and informers do). The
change takes effect immediately; no pod restart is needed.

## Common RBAC mistakes

| Symptom | Likely mistake |
|---|---|
| Works for one object, 403 for "all" | Role has `get` but not `list` |
| 403 for something in an API group | Wrong `apiGroups` (e.g. Deployments are in `apps`, not `""`) |
| 403 even though the Role looks right | RoleBinding points to the wrong SA name or namespace, or to a ClusterRole with `kind: Role` |
| 403 in another namespace | Role/RoleBinding only apply in their own namespace |
| Pod uses the wrong identity | `serviceAccountName` missing, so the pod runs as `default` |

## Least privilege

The tempting fix is `cluster-admin` or a ClusterRoleBinding. That would work and
would also let a compromised tool delete or read anything in the cluster. Grant the
narrowest verbs on the narrowest resources in the narrowest scope, and check with
`kubectl auth can-i` that what should be denied is denied.

## Interview talking point

"A 403 from the API server tells me the subject, verb, resource and namespace. I
reproduce it with kubectl auth can-i --as the ServiceAccount, find which part doesn't
match the Role and RoleBinding, and add only the missing permission. Then I verify the
things that should stay denied are still denied."
