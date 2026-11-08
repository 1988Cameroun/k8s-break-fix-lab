## Hint 1

`Running` means the container process is up. `Ready` means the readiness probe
passes. The probe's result is in the pod events:

    kubectl -n lab-05 describe pod -l app=catalog | grep -i -A2 readiness

## Hint 2

The event says the probe failed with "connection refused". That's a port problem,
not a path problem. Which port does nginx listen on? (Look at the ConfigMap.)

## Hint 3

Point the probe at the right port. Using the named port `http` is even better:

    kubectl -n lab-05 edit deploy catalog
