# Solution 05 · Running but never Ready: a failing probe

## Root cause

The readiness probe checked `/healthz` on port **8080**, but nginx listens on port
**80**. Every probe got "connection refused", so the kubelet never marked the pods
Ready. Pods that aren't Ready are left out of the Service's endpoints, so the app
received no traffic even though it was healthy.

## How to diagnose it

```bash
kubectl -n lab-05 get pods
# catalog-xxx   0/1   Running   0   2m     <-- running, not ready

kubectl -n lab-05 describe pod -l app=catalog
# Readiness: http-get http://:8080/healthz
# Warning  Unhealthy  Readiness probe failed: Get "http://10.244.1.9:8080/healthz":
#          dial tcp 10.244.1.9:8080: connect: connection refused

# Prove what the app really serves:
kubectl -n lab-05 port-forward deploy/catalog 8081:80 &
curl -s localhost:8081/healthz      # ok
```

Reading probe errors:

| Error | Meaning |
|---|---|
| `connection refused` | Nothing listening on that port: wrong port, or app not started yet |
| `HTTP probe failed with statuscode: 404` | Right port, wrong path |
| `context deadline exceeded` / `timeout` | App too slow: raise `timeoutSeconds` or fix the endpoint |

## The fix

```bash
kubectl -n lab-05 patch deploy catalog --type=json -p \
  '[{"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/httpGet/port","value":"http"}]'
```

## Readiness vs liveness vs startup

- **Readiness** failing: the pod is removed from Service endpoints. Nothing restarts.
- **Liveness** failing: the kubelet **restarts** the container. A wrong liveness probe
  causes a restart loop, which is much worse. Be careful with liveness.
- **Startup**: holds off the other probes until a slow-starting app is up.

A readiness probe should check "can I serve traffic right now". A liveness probe should
only check "is this process stuck beyond recovery". Don't make liveness depend on a
database, or one database outage restarts every pod at once.

## Interview talking point

"Running but not Ready is almost always the readiness probe. I read the probe failure
event: 'connection refused' means port, 404 means path, timeout means slow. I use
named ports in probes so they can't drift from the container port."
