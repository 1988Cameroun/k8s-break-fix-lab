# 05 · Running but never Ready: a failing probe

**Level:** easy · **Namespace:** `lab-05`

## The ticket

> We added health checks to `catalog` so Kubernetes stops sending traffic to broken
> pods. Since then, every pod shows `0/1` and the `catalog` Service has no endpoints,
> even though the logs look healthy.

## Your goal

- All 3 `catalog` replicas are Ready.

## Rules

- Keep the readiness probe and keep it pointed at the `/healthz` endpoint.
  Deleting the probe "fixes" the symptom and removes the protection.
