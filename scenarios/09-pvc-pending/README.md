# 09 · PVC stuck Pending: the missing StorageClass

**Level:** medium · **Namespace:** `lab-09`

## The ticket

> The `uploader` service stores files on a 1Gi persistent volume. In this cluster its
> pod has been `Pending` since it was deployed, and so has its PersistentVolumeClaim.
> The manifests were written for our cloud environment.

## Your goal

- The `uploads` PVC is `Bound` and `uploader` is Running and Ready.

## Rules

- The claim must still be called `uploads` and request at least `1Gi`.
- Use storage that actually exists in this cluster.
- Some PVC fields can't be changed after creation. You may need to replace the claim
  (it holds no data yet).
