# Solution 04 · Service with no endpoints

## Root cause

There were two independent bugs in the Service:

1. **Selector mismatch.** The Service selected `app: checkout-api`, but the pods are
   labeled `app: checkout, tier: api`. No pods matched, so the Service had no endpoints
   and traffic went nowhere.
2. **Wrong targetPort.** The Service forwarded to port `8080`, but nginx listens on `80`.
   Even after fixing the selector, connections were refused.

Fixing only the first bug and stopping is the classic trap.

## How to diagnose it

```bash
kubectl -n lab-04 describe svc checkout
# Selector:   app=checkout-api
# TargetPort: 8080/TCP
# Endpoints:  <none>                  <-- bug 1

kubectl -n lab-04 get pods --show-labels
# checkout-xxx   1/1 Running   app=checkout,tier=api

# After fixing the selector:
kubectl -n lab-04 get endpointslices -l kubernetes.io/service-name=checkout
# ADDRESSTYPE  PORTS  ENDPOINTS
# IPv4         8080   10.244.1.5,10.244.2.7   <-- endpoints exist, port is wrong

kubectl -n lab-04 exec deploy/toolbox -- wget -qO- -T 3 http://checkout
# wget: can't connect to remote host: Connection refused   <-- bug 2
```

A useful way to split the problem: if a request to the **pod IP and port** works but
the **Service name** doesn't, the problem is in the Service (selector, ports) or
kube-proxy. If even the pod IP fails, the problem is in the pod or a NetworkPolicy
(scenario 08).

## The fix

```bash
kubectl -n lab-04 patch svc checkout --type=json -p '[
  {"op":"replace","path":"/spec/selector","value":{"app":"checkout","tier":"api"}},
  {"op":"replace","path":"/spec/ports/0/targetPort","value":"http"}
]'
```

Note the JSON patch `replace` on the selector. A strategic merge patch would *merge*
the maps and leave the stale `app: checkout-api` key in place.

## Prevention

- Use named ports (`targetPort: http`). If the container port number changes, the
  Service follows it automatically.
- Generate the Service and Deployment labels from one place (Helm `_helpers.tpl`,
  Kustomize `labels`) so they can't drift apart.
- Add a smoke test in CI that requests the Service after deploying.

## Interview talking point

"When a Service doesn't work, I check its endpoints first. No endpoints means the
selector or readiness is wrong. Endpoints but no response means the ports are wrong
or something is blocking traffic. Then I test the pod IP directly to split Service
problems from pod problems."
