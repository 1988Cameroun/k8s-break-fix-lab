# Kubernetes troubleshooting playbook

The method behind every scenario in this lab, on one page.

## 1. Start from the symptom, not a guess

```bash
kubectl get pods -n <ns> -o wide          # STATUS, RESTARTS, NODE
kubectl get events -n <ns> --sort-by=.lastTimestamp | tail -20
```

| Pod status | Where the problem is | First command | Lab |
|---|---|---|---|
| `Pending` | Scheduling: resources, taints, affinity, unbound PVC | `kubectl describe pod` → FailedScheduling | 03, 09 |
| `ImagePullBackOff` / `ErrImagePull` | Image name/tag, registry auth, network, architecture | `kubectl describe pod` → Events | 02, 12 |
| `CreateContainerConfigError` | Missing Secret/ConfigMap/key | `kubectl describe pod` → Events | 11 |
| `CrashLoopBackOff` | App starts then exits | `kubectl logs --previous` + exit code | 01, 06 |
| `Running` but `0/1` | Readiness probe failing | `kubectl describe pod` → Unhealthy event | 05 |
| `Running 1/1` but requests fail | Service, DNS, NetworkPolicy | endpoints → DNS → policies | 04, 07, 08 |
| `403 Forbidden` in app logs | RBAC | `kubectl auth can-i ... --as=` | 10 |
| Rollout never finishes | New pods not becoming Ready | `kubectl get rs`, `rollout history` | 12 |

## 2. Exit codes

| Code | Meaning |
|---|---|
| 0 | Exited normally (a long-running app shouldn't) |
| 1 | Application error |
| 126 / 127 | Command not executable / not found |
| 137 | SIGKILL: `OOMKilled`, or killed after the grace period |
| 143 | SIGTERM: normal shutdown |

## 3. The network path, one hop at a time

```
client pod ──DNS──▶ Service name ──▶ ClusterIP ──kube-proxy──▶ EndpointSlice ──▶ pod IP:targetPort
               (07)                (04: selector, ports)        (05: readiness)   (08: NetworkPolicy)
```

```bash
kubectl exec <client> -- nslookup <svc>.<ns>.svc.cluster.local   # DNS
kubectl get endpointslices -l kubernetes.io/service-name=<svc>     # any Ready endpoints?
kubectl exec <client> -- wget -qO- -T 3 http://<pod-ip>:<port>     # bypass the Service
kubectl get networkpolicy -n <ns>                                  # what selects the target?
```

"Connection refused" means something answered and said no (nothing listening, wrong
port). A **timeout** means packets were dropped (NetworkPolicy, firewall).

## 4. Fix like it's production

1. Find the root cause before changing anything, and write it down.
2. Make the smallest change that fixes it. Don't remove the safety mechanism
   (probes, limits, NetworkPolicy, RBAC) that surfaced the problem.
3. Confirm the fix, and confirm what should still be blocked is still blocked.
4. Put the change in Git. Ask what would have caught it earlier.
