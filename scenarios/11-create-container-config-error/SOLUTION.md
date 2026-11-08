# Solution 11 · CreateContainerConfigError: secret and config refs

## Root cause

Two references in the pod spec pointed at things that don't exist:

1. `DB_PASSWORD` read key `DB_PASSWORD` from Secret `payment-db`, but the key in the
   Secret is `db-password`. Keys are case-sensitive.
2. `LOG_LEVEL` read ConfigMap `payments-config`, but the ConfigMap is called
   `payment-config` (no "s").

Before starting a container the kubelet resolves every `secretKeyRef` and
`configMapKeyRef`. If one is missing it refuses to create the container and reports
`CreateContainerConfigError`. It reports one failure at a time, so the second bug only
appeared after the first was fixed.

## How to diagnose it

```bash
kubectl -n lab-11 get pods
# payments-xxx   0/1   CreateContainerConfigError   0   1m

kubectl -n lab-11 describe pod -l app=payments
# Warning  Failed  Error: couldn't find key DB_PASSWORD in Secret lab-11/payment-db

kubectl -n lab-11 get secret payment-db -o jsonpath='{.data}'
# {"db-password":"bGFi..."}            <-- the real key name

# After fixing the key:
# Warning  Failed  Error: configmap "payments-config" not found

kubectl -n lab-11 get configmap
# payment-config
```

There are no app logs because the container was never created. That's the difference
from CrashLoopBackOff (scenario 01), where the app starts and exits.

## The fix

```bash
kubectl -n lab-11 patch deploy payments --type=json -p '[
  {"op":"replace","path":"/spec/template/spec/containers/0/env/0/valueFrom/secretKeyRef/key","value":"db-password"},
  {"op":"replace","path":"/spec/template/spec/containers/0/env/1/valueFrom/configMapKeyRef/name","value":"payment-config"}
]'
```

## Related behaviours worth knowing

- Mark a reference `optional: true` if the app can start without it.
- Env vars are read **once at container start**. Changing the Secret later doesn't
  update a running pod. Mounted Secret/ConfigMap **volumes** do update (after a delay),
  except when mounted with `subPath`.
- Tools like Reloader, or a checksum annotation in a Helm template, restart pods when
  their config changes.
- Kubernetes Secrets are base64-encoded, not encrypted. Turn on encryption at rest and
  restrict `get secrets` via RBAC (scenario 10), or use External Secrets / Sealed Secrets.

## Interview talking point

"CreateContainerConfigError means the container was never created, so there are no logs.
The event names the missing Secret, ConfigMap or key. I compare it with what exists in
the namespace, fix it, and check the events again because the kubelet reports one
missing reference at a time."
