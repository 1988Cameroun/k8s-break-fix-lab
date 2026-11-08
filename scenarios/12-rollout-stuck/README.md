# 12 · Stuck rollout: a bad release, half deployed

**Level:** medium · **Namespace:** `lab-12`

## The ticket

> The CD pipeline says the `web` release (v2) **failed** after timing out. Oddly,
> customers haven't noticed anything. The on-call engineer wants the service back in
> a clean, fully rolled-out state **right now**, and a short explanation of why
> users weren't affected.

## Your goal

- The `web` rollout completes: 3/3 replicas updated, ready and available.
- All pods run an image that actually works.
- Be able to explain why the failed release didn't cause an outage.

## Rules

- Don't delete and recreate the Deployment. Recover it like you would in production.
