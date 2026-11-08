## Hint 1

`Pending` means the pod hasn't been placed on a node yet. The scheduler explains
why in the pod's events:

    kubectl -n lab-03 describe pod -l app=report-generator | tail -n 5

## Hint 2

Compare what the pod asks for with what a node can offer:

    kubectl get nodes -o custom-columns=NAME:.metadata.name,CPU:.status.allocatable.cpu,MEM:.status.allocatable.memory
    kubectl describe node <a-worker> | grep -A8 "Allocated resources"

## Hint 3

The scheduler places pods by **requests**, not by actual usage. A small busy loop
needs very little. Try `kubectl set resources` with requests around `50m` CPU and
`32Mi` memory, and limits a little above that.
