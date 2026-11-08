# Solution 08 · NetworkPolicy: allow rule that allows nothing

## Root cause

`default-deny-ingress` blocked all ingress to every pod in the namespace, as intended.
The allow rule meant to open `web → api` had two bugs, so it matched nothing:

1. **Wrong label.** It allowed pods with `role: frontend`, but `web` is labeled
   `tier: frontend`. No pod matched.
2. **Wrong port.** It allowed port `8080`. NetworkPolicy ports are the **destination
   pod's** port after Service translation, not the Service port. nginx listens on `80`.

With nothing allowed, the default deny dropped the traffic silently, which shows up as
a **timeout** rather than "connection refused".

## How to diagnose it

```bash
kubectl -n lab-08 exec deploy/web -- wget -qO- -T 3 http://api
# wget: download timed out          <-- a timeout, not a refusal: something is dropping packets

kubectl -n lab-08 get endpointslices -l kubernetes.io/service-name=api
# endpoints exist, so the Service is fine

kubectl -n lab-08 get networkpolicy
# default-deny-ingress, allow-web-to-api

kubectl -n lab-08 describe networkpolicy allow-web-to-api
# Allowing ingress traffic:
#   To Port: 8080/TCP
#   From:  PodSelector: role=frontend

kubectl -n lab-08 get pods --show-labels
# web-xxx   app=web,tier=frontend     <-- no 'role' label
```

A quick trick to confirm a NetworkPolicy is the cause: temporarily test from a pod
in another namespace, or list the policies selecting the target pod. Don't delete
policies on a production cluster to "see if it helps".

## The fix

```bash
kubectl -n lab-08 patch networkpolicy allow-web-to-api --type=json -p '[
  {"op":"replace","path":"/spec/ingress/0/from/0/podSelector/matchLabels","value":{"tier":"frontend"}},
  {"op":"replace","path":"/spec/ingress/0/ports/0/port","value":80}
]'
```

Using `port: http` (the named container port) is also valid, and it survives port changes.

## Things that trip people up

- Policies are **allow-lists** and **additive**. There is no "deny" rule; the deny comes
  from a pod being selected by any policy of that type.
- Once you add an **egress** default deny, you must explicitly allow DNS (UDP and TCP 53
  to kube-dns), or every name lookup fails.
- `from: [podSelector, namespaceSelector]` (two list items) means OR. A single item
  with both selectors means AND. One dash changes the meaning.
- NetworkPolicy only works if the CNI enforces it. Flannel alone does not.

## Interview talking point

"A timeout between pods, when the Service has endpoints, points to a NetworkPolicy
or firewall. I list the policies that select the destination pod and check each rule's
selectors and ports against the real labels. NetworkPolicy ports are the pod's port,
not the Service port. I fix the allow rule rather than removing the default deny."
