# Solution 09 · PVC stuck Pending: the missing StorageClass

## Root cause

The PVC asked for `storageClassName: fast-ssd`. That class exists in the cloud
environment the manifests were written for, but not in this cluster. With no class
(and so no provisioner) to create a volume, the claim stayed `Pending`, and the pod
that needs it couldn't be scheduled.

## How to diagnose it

```bash
kubectl -n lab-09 get pods,pvc
# pod/uploader-xxx   0/1   Pending
# pvc/uploads        Pending              fast-ssd

kubectl -n lab-09 describe pod -l app=uploader
# Warning  FailedScheduling  ... pod has unbound immediate PersistentVolumeClaims

kubectl -n lab-09 describe pvc uploads
# Warning  ProvisioningFailed  storageclass.storage.k8s.io "fast-ssd" not found

kubectl get storageclass
# NAME                 PROVISIONER             VOLUMEBINDINGMODE
# standard (default)   rancher.io/local-path   WaitForFirstConsumer
```

## The fix

`storageClassName` is immutable on an existing PVC, so the claim has to be replaced:

```bash
kubectl -n lab-09 scale deploy/uploader --replicas=0
kubectl -n lab-09 delete pvc uploads
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: uploads
  namespace: lab-09
spec:
  accessModes: [ReadWriteOnce]
  storageClassName: standard
  resources:
    requests:
      storage: 1Gi
EOF
kubectl -n lab-09 scale deploy/uploader --replicas=1
```

Scaling to 0 first matters: the `kubernetes.io/pvc-protection` finalizer keeps a
claim that a pod is using in `Terminating` until that pod is gone.

**Warning:** in a real environment, deleting a PVC can delete its data, depending on
the PersistentVolume's `reclaimPolicy` (`Delete` is the default for dynamic
provisioning). It was safe here only because the claim was never bound.

## WaitForFirstConsumer

The `standard` class uses `WaitForFirstConsumer`. A new PVC stays `Pending` **until a pod
uses it**, so the volume is created on the node where the pod is scheduled. That kind of
Pending is normal. Check the events before assuming something is broken.

## Prevention

- Keep the storage class per environment in Helm values or a Kustomize overlay.
- Or omit `storageClassName` and rely on each cluster's default class.
- Use `reclaimPolicy: Retain` for important data, and back it up (e.g. Velero).

## Interview talking point

"For a Pending pod with a volume, I follow pod → PVC → StorageClass and read the events
at each step. Here the class didn't exist. storageClassName is immutable, so I'd replace
the claim, after checking the reclaim policy so I don't delete real data."
