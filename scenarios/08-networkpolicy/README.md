# 08 · NetworkPolicy: allow rule that allows nothing

**Level:** hard · **Namespace:** `lab-08`

## The ticket

> Security asked us to lock down `lab-08`: deny all ingress by default, then allow
> only the `web` frontend to call the `api` backend on port 80. After the change,
> `web` gets timeouts calling `api`. Everything is Running and Ready.

## Your goal

- `web` can reach `http://api`.
- Nothing else can. The `intruder` pod must still be blocked from `api`.

## Rules

- Keep the `default-deny-ingress` policy.
- Don't change pod labels. Fix the policy, not the workloads.

> **Note:** NetworkPolicy is enforced by the CNI plugin. This lab's kind cluster uses
> kindnet, which enforces NetworkPolicy in kind v0.25 and newer. `./lab.sh check` warns
> you if your cluster doesn't enforce it.
