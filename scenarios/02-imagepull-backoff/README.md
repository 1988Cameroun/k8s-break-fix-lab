# 02 · ImagePullBackOff: the version that doesn't exist

**Level:** easy · **Namespace:** `lab-02`

## The ticket

> We bumped the `storefront` web server to "the newest nginx" in today's release.
> The new pods never start, and the release pipeline is stuck waiting.

## Your goal

- `storefront` runs 2 Available replicas on an **nginx 1.27 Alpine** image that exists.

## Rules

- Keep using the official `nginx` image.
