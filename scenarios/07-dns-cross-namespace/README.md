# 07 · DNS: "bad address" across namespaces

**Level:** medium · **Namespaces:** `lab-07`, `lab-07-data`

## The ticket

> The platform team moved shared services into their own namespace, `lab-07-data`.
> Since then the `orders` service (in `lab-07`) can't reach the `pricing` service.
> `orders` pods never become Ready. Someone says "DNS is broken in the cluster."

## Your goal

- `orders` is Ready and can reach `pricing`.

## Rules

- `pricing` stays in `lab-07-data`. Don't copy or move it into `lab-07`.
- Is cluster DNS actually broken? Prove it one way or the other before changing anything.
