# Solution 03 · Pending: requests no node can satisfy

## Root cause

Each pod requested 64 CPUs and 256 GiB of memory. No node in a laptop kind cluster
has that much allocatable capacity, so the scheduler could not place the pods and
left them `Pending`. The app never started, which is why there were no logs.

## How to diagnose it

```bash
kubectl -n lab-03 get pods
# report-generator-xxx   0/1   Pending   0   5m

kubectl -n lab-03 describe pod -l app=report-generator
# Events:
#   Warning  FailedScheduling  0/3 nodes are available:
#     1 node(s) had untolerated taint {node-role.kubernetes.io/control-plane: },
#     2 Insufficient cpu, 2 Insufficient memory.

kubectl get nodes -o custom-columns=NAME:.metadata.name,CPU:.status.allocatable.cpu,MEM:.status.allocatable.memory
```

The `FailedScheduling` message is a per-node breakdown. Learn to read it: it also
reports taints, node selectors and affinity, unbound PVCs (scenario 09) and pod
anti-affinity.

## The fix

```bash
kubectl -n lab-03 set resources deploy/report-generator \
  --requests=cpu=50m,memory=32Mi --limits=cpu=200m,memory=64Mi
```

## Why requests and limits both matter

- **Requests** reserve capacity. The scheduler uses them for placement, and they set
  the pod's CPU share under contention.
- **Limits** cap usage. Going over the memory limit gets the container OOMKilled
  (scenario 06). Going over the CPU limit gets it throttled.
- Requests equal to limits for every resource gives the pod the `Guaranteed` QoS class,
  which is the last to be evicted under node pressure.

## Prevention

- Keep per-environment values in Helm values files or Kustomize overlays instead of
  copying manifests between repos.
- Set a `LimitRange` (defaults and maximums) and a `ResourceQuota` per namespace so
  outsized requests are rejected at admission with a clear error.
- Base requests on real usage (`kubectl top`, Prometheus, or VPA in recommendation mode).

## Interview talking point

"Pending means a scheduling problem, so I read the FailedScheduling event, which
lists why each node was rejected. Here it was requests sized for production. I'd fix
it per environment and add a LimitRange so it fails fast next time."
