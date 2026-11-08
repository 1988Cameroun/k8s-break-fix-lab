# 04 · Service with no endpoints

**Level:** medium · **Namespace:** `lab-04`

## The ticket

> The `checkout` pods are all Running and Ready. But every request to the `checkout`
> Service fails. From the `toolbox` pod:
>
>     kubectl -n lab-04 exec deploy/toolbox -- wget -qO- -T 3 http://checkout
>     wget: can't connect to remote host

## Your goal

- `http://checkout` returns the nginx welcome page from inside the namespace.

## Rules

- The `checkout` Deployment is correct. Don't change it. The problem is elsewhere.
- There may be more than one problem.
