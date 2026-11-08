# 01 · CrashLoopBackOff: the missing config file

**Level:** easy · **Namespace:** `lab-01`

## The ticket

> The `inventory-api` deployment has been restarting all morning. Nobody changed the
> application image. The only recent change was a teammate "tidying up" the volume
> mounts in the Deployment manifest.

## Your goal

- `inventory-api` is Running, Ready, and stops restarting.
- The app loads its configuration from the `app-config` ConfigMap.

## Rules

- Don't change the container image or its command. Fix the Kubernetes config.
