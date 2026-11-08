# Solution 01 · CrashLoopBackOff: the missing config file

## Root cause

The ConfigMap was mounted at `/etc/inventory-config`, but the app reads
`/etc/inventory/config.yaml`. The file never existed where the app looked, so the
process exited with code 1 on every start. The kubelet restarted it with an
increasing back-off delay, which is what `CrashLoopBackOff` means.

## How to diagnose it

```bash
kubectl -n lab-01 get pods
# inventory-api-xxx   0/1   CrashLoopBackOff   5 (40s ago)

kubectl -n lab-01 logs deploy/inventory-api --previous
# FATAL: config file not found: /etc/inventory/config.yaml

kubectl -n lab-01 describe pod -l app=inventory-api
# Last State: Terminated  Reason: Error  Exit Code: 1
# Mounts: /etc/inventory-config from config (ro)   <-- the mismatch
```

Exit code 1 means the application chose to exit. Compare that with exit code 137
(killed, often OOM, see scenario 06) or 127 (command not found).

## The fix

```bash
kubectl -n lab-01 patch deploy inventory-api --type=json -p \
  '[{"op":"replace","path":"/spec/template/spec/containers/0/volumeMounts/0/mountPath","value":"/etc/inventory"}]'
```

In a real team you would change the manifest in Git and let CI/CD or GitOps apply it,
so the cluster and the repo don't drift apart.

## Prevention

- Keep the config path in one place, for example an env var such as
  `CONFIG_PATH` used by both the app and the mount.
- Test manifest changes in a dev or kind cluster in CI before merging, as this repo does.
- Use `kubectl logs --previous` as a first step for any crashing container.

## Interview talking point

"For CrashLoopBackOff I check the previous container's logs and the exit code first.
That tells me whether the app exited on purpose, was killed, or couldn't start.
Then I compare what the app expects (paths, env vars, ports) with what the pod spec
actually provides."
