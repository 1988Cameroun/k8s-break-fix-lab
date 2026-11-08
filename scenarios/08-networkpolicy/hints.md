## Hint 1

Prove where the problem is. Is the Service fine (endpoints exist)? Does the request
fail from **every** pod, or only some?

    kubectl -n lab-08 get endpointslices -l kubernetes.io/service-name=api
    kubectl -n lab-08 exec deploy/web -- wget -qO- -T 3 http://api
    kubectl -n lab-08 get networkpolicy

## Hint 2

NetworkPolicies are additive: traffic is allowed if **any** policy allows it. So the
question is why `allow-web-to-api` matches nothing. Compare its `from` selector with
the labels on the `web` pod:

    kubectl -n lab-08 describe networkpolicy allow-web-to-api
    kubectl -n lab-08 get pods --show-labels

## Hint 3

There are two problems in `allow-web-to-api`. One is the label in the `from`
selector. The other is the port: does a NetworkPolicy port refer to the **Service**
port or the **pod's** port? And which port does nginx listen on?
