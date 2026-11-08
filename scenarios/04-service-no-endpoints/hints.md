## Hint 1

A Service is just a selector plus ports. Check which pods it actually found:

    kubectl -n lab-04 get endpointslices -l kubernetes.io/service-name=checkout
    kubectl -n lab-04 describe svc checkout

## Hint 2

"Endpoints: <none>" means the selector matches no pods. Compare it with the real
pod labels:

    kubectl -n lab-04 get pods --show-labels

## Hint 3

After fixing the selector, the endpoints appear but requests still fail. A Service
forwards `port` to the pod's `targetPort`. Which port is nginx listening on? You can
use the number or the container port's **name** (`http`).
