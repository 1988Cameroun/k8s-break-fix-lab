# Solution 06 · OOMKilled: the memory limit is too small

## Root cause

The container's memory limit was `100Mi`, but the app allocates a 150 MB buffer (plus
the Python runtime). When the container's memory use went over its cgroup limit, the
Linux kernel's OOM killer sent it SIGKILL. The process had no chance to log anything,
which is why the logs just stopped. The kubelet restarted it, it was killed again, and
the pod went into CrashLoopBackOff.

## How to diagnose it

```bash
kubectl -n lab-06 get pods
# image-resizer-xxx   0/1   CrashLoopBackOff   4   3m

kubectl -n lab-06 describe pod -l app=image-resizer
# Last State:  Terminated
#   Reason:    OOMKilled
#   Exit Code: 137
# Limits:
#   memory: 100Mi

kubectl -n lab-06 logs deploy/image-resizer --previous
# image-resizer starting, allocating 150 MB working buffer...
# (nothing else: killed before it could print)

# With metrics-server installed, compare real usage with the limit:
kubectl -n lab-06 top pod
```

Exit codes worth knowing: **137** = SIGKILL (OOM, or killed after the termination
grace period), **143** = SIGTERM (normal shutdown), **1** = app error,
**126/127** = command not executable / not found.

## The fix

```bash
kubectl -n lab-06 set resources deploy/image-resizer \
  --requests=memory=192Mi --limits=memory=256Mi
```

## Container OOM vs node memory pressure

- **OOMKilled (this scenario):** one container went over **its own limit**. The pod
  stays on the node and the container restarts.
- **Evicted:** the **node** ran low on memory. The kubelet evicts pods, starting with
  `BestEffort`, then `Burstable` pods using the most above their requests. The pod is
  removed and its controller recreates it elsewhere.

Setting memory requests close to real usage protects you from both: the scheduler
won't overpack the node, and your pod is not the first to be evicted.

## Prevention

- Size limits from observed usage (Prometheus `container_memory_working_set_bytes`,
  or VPA in recommendation mode), with headroom.
- Alert on `kube_pod_container_status_last_terminated_reason{reason="OOMKilled"}`.
- For runtimes like the JVM or Node.js, set their heap size relative to the
  container limit, or they'll use more than you expect.

## Interview talking point

"Logs that stop with no error suggest the process was killed. I check
Last State in describe: OOMKilled with exit code 137 means it went over its memory
limit. I'd size the limit from real usage with headroom, not just remove it, and
alert on OOM kills."
