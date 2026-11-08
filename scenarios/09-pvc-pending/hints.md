## Hint 1

The pod is Pending because of its volume. Follow the chain: pod → PVC → StorageClass.

    kubectl -n lab-09 describe pod -l app=uploader | tail -n 5
    kubectl -n lab-09 describe pvc uploads

## Hint 2

What storage classes does this cluster actually have?

    kubectl get storageclass

Note which one is marked `(default)` and its `VOLUMEBINDINGMODE`.

## Hint 3

`storageClassName` on a PVC is immutable, so `kubectl edit` will be rejected. Scale
the Deployment to 0, delete the PVC, recreate it with a class that exists (or no
`storageClassName` at all, to get the default), then scale back to 1.
