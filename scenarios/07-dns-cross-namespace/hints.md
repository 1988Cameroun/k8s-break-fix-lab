## Hint 1

Start with the error itself:

    kubectl -n lab-07 logs deploy/orders

"bad address" means the name could not be resolved. Before blaming cluster DNS, test
whether DNS works **at all** from that pod:

    kubectl -n lab-07 exec deploy/orders -- nslookup kubernetes.default.svc.cluster.local

## Hint 2

DNS works. So why doesn't `pricing` resolve? Look at the pod's resolver config:

    kubectl -n lab-07 exec deploy/orders -- cat /etc/resolv.conf

Short names are expanded using the `search` list. Which namespace does the first
search domain point to?

## Hint 3

A short name like `pricing` only finds Services in the **pod's own namespace**. For
another namespace use `<service>.<namespace>` or the full name
`<service>.<namespace>.svc.cluster.local`. Update the `PRICING_URL` env var:

    kubectl -n lab-07 set env deploy/orders PRICING_URL=...
