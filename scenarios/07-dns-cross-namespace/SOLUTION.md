# Solution 07 · DNS: "bad address" across namespaces

## Root cause

Cluster DNS was fine. `orders` used the short name `pricing`. Inside a pod, short
names are expanded with the search domains in `/etc/resolv.conf`, and the first one is
the pod's **own** namespace (`lab-07.svc.cluster.local`). There's no `pricing` Service
in `lab-07`, so the name didn't resolve. The Service lives in `lab-07-data`.

## How to diagnose it

```bash
kubectl -n lab-07 logs deploy/orders
# ERROR: cannot reach http://pricing: wget: bad address 'pricing'

# 1. Is DNS working at all?
kubectl -n lab-07 exec deploy/orders -- nslookup kubernetes.default.svc.cluster.local
# Name: kubernetes.default.svc.cluster.local   <-- yes, DNS is fine

# 2. How are short names expanded?
kubectl -n lab-07 exec deploy/orders -- cat /etc/resolv.conf
# search lab-07.svc.cluster.local svc.cluster.local cluster.local
# options ndots:5

# 3. Where does the Service really live?
kubectl get svc -A | grep pricing
# lab-07-data   pricing   ClusterIP   10.96.x.x   80/TCP

kubectl -n lab-07 exec deploy/orders -- nslookup pricing.lab-07-data.svc.cluster.local
# resolves
```

(busybox's `nslookup` doesn't apply search domains reliably, so give it full names.
The app's own `wget` does use the search list.)

If DNS were really broken, the `kubernetes.default` lookup would fail too. Then you'd
check the CoreDNS pods and their logs (`kubectl -n kube-system logs -l k8s-app=kube-dns`),
the `kube-dns` Service endpoints, and any NetworkPolicy blocking egress to port 53.

## The fix

```bash
kubectl -n lab-07 set env deploy/orders \
  PRICING_URL=http://pricing.lab-07-data.svc.cluster.local
```

`http://pricing.lab-07-data` also works, because the `svc.cluster.local` search domain
completes it.

## About `ndots:5`

With `ndots:5`, any name with fewer than 5 dots is tried against every search domain
first. A lookup for `api.example.com` therefore becomes several failed queries before
the real one. For busy apps calling external hosts, use fully qualified names with a
trailing dot (`api.example.com.`) or lower `ndots` in the pod's `dnsConfig`.

## Interview talking point

"Before saying 'DNS is broken', I test a name that must resolve, like
kubernetes.default. If that works, DNS is fine and the problem is the name. Short
names only resolve within the pod's own namespace, so cross-namespace calls need
service.namespace."
