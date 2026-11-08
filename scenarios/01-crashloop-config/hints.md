## Hint 1

A container in CrashLoopBackOff is starting and then exiting. The app usually
tells you why. Look at its logs, including the logs of the *previous* (crashed)
container:

    kubectl -n lab-01 logs deploy/inventory-api --previous

## Hint 2

The app expects a file at one path. Compare that path with where the volume is
actually mounted:

    kubectl -n lab-01 get deploy inventory-api -o yaml | grep -A3 volumeMounts

## Hint 3

The ConfigMap's key `config.yaml` becomes a file inside the `mountPath` directory.
For the file to be at `/etc/inventory/config.yaml`, which directory must the volume
be mounted at? Fix it with `kubectl edit` or by editing the manifest and re-applying.
