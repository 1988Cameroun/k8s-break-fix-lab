# Solution 12 · Stuck rollout: a bad release, half deployed

## Root cause

Release v2 changed the image to `nginx:1.27.99-alpine`, which doesn't exist. The
Deployment created a new ReplicaSet, and its first pod went into `ImagePullBackOff`.

The rolling update was configured with `maxSurge: 1` and `maxUnavailable: 0`:

- `maxSurge: 1` lets Kubernetes add **one** extra pod above the desired 3.
- `maxUnavailable: 0` means it may never drop below 3 available pods, so it can only
  remove an old pod after a new one becomes Ready.

The new pod never became Ready, so no old pod was ever removed. All 3 v1 pods kept
serving traffic, which is why users saw nothing. After `progressDeadlineSeconds` (60s)
the Deployment marked itself `Progressing=False, reason=ProgressDeadlineExceeded`, and
that's what the pipeline reported as a failure.

## How to diagnose it

```bash
kubectl -n lab-12 rollout status deploy/web
# error: deployment "web" exceeded its progress deadline

kubectl -n lab-12 get rs -l app=web
# NAME            DESIRED   CURRENT   READY
# web-6d4cf56db6  3         3         3      <-- v1, still serving
# web-7c9f8b5d4   1         1         0      <-- v2, stuck

kubectl -n lab-12 get pods -l app=web
# web-7c9f8b5d4-xxx   0/1   ImagePullBackOff

kubectl -n lab-12 rollout history deploy/web
# REVISION  CHANGE-CAUSE
# 1         v1: initial release (nginx 1.27)
# 2         v2: bump nginx to 1.27.99
```

## The fix

```bash
kubectl -n lab-12 rollout undo deploy/web        # back to revision 1
kubectl -n lab-12 rollout status deploy/web
```

`rollout undo` copies the old revision's pod template into a **new** revision (3). It
doesn't rewrite history. Use `--to-revision=N` to pick a specific one. Update the
`kubernetes.io/change-cause` annotation afterwards, or revision 3 will still be
labelled "v2" in the history.

In a GitOps setup (Argo CD / Flux) you'd revert the commit in Git instead. An
`undo` in the cluster would be overwritten on the next sync.

## Why this matters

| Setting | Effect |
|---|---|
| `maxUnavailable: 0` | Never lose capacity during a rollout. Bad releases stall instead of causing an outage. |
| `maxSurge` | How many extra pods may exist during the rollout. Needs spare cluster capacity. |
| `progressDeadlineSeconds` | When to declare the rollout failed. Your pipeline should watch for this. |
| readiness probe | The gate for all of it. Without one, a broken app is "Ready" instantly and the rollout continues happily. |
| `revisionHistoryLimit` | How many old ReplicaSets are kept to undo to. |

Next steps after this would be automated rollback in the pipeline on
`ProgressDeadlineExceeded`, or progressive delivery (Argo Rollouts / Flagger) with
canary analysis.

## Interview talking point

"The rollout failed safely because maxUnavailable was 0 and there was a readiness
probe: the new pods never became Ready, so no old pods were removed. I'd check the
ReplicaSets to confirm the old version is still serving, roll back with rollout undo
(or revert in Git if we use GitOps), then fix the release."
