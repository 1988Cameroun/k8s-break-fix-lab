## Hint 1

`CreateContainerConfigError` means the kubelet couldn't build the container's
configuration, so the container was never created. The event says which reference
failed:

    kubectl -n lab-11 describe pod -l app=payments | tail -n 5

## Hint 2

Compare the reference with what really exists. Note that a Secret's **keys** are
case-sensitive and must match exactly:

    kubectl -n lab-11 get secret payment-db -o jsonpath='{.data}'
    kubectl -n lab-11 get configmap

## Hint 3

Fix the Secret key reference, then check the events again. The kubelet reports one
missing reference at a time, so a second problem may only appear after you fix the
first. Look closely at the ConfigMap **name**.
