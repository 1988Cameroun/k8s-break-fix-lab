# Solution 02 · ImagePullBackOff: the version that doesn't exist

## Root cause

The image tag `nginx:1.72-alpine` does not exist (the digits were transposed from
`1.27`). The kubelet asked the registry for the image, got "not found", and backed off
between retries. That shows up as `ErrImagePull`, then `ImagePullBackOff`.

## How to diagnose it

```bash
kubectl -n lab-02 get pods
# storefront-xxx   0/1   ImagePullBackOff   0   1m

kubectl -n lab-02 describe pod -l app=storefront
# Events:
#   Failed to pull image "nginx:1.72-alpine": ... not found
```

Read the error text closely, because the same status has several causes:

| Event text | Likely cause |
|---|---|
| `not found` / `manifest unknown` | Wrong tag or image name |
| `unauthorized` / `authentication required` | Private registry, missing or wrong `imagePullSecrets` |
| `toomanyrequests` | Registry rate limit (common with Docker Hub) |
| `i/o timeout` / `no such host` | Node can't reach the registry (DNS, proxy, firewall) |
| `no matching manifest for linux/arm64` | Image not built for the node's CPU architecture |

## The fix

```bash
kubectl -n lab-02 set image deploy/storefront nginx=nginx:1.27-alpine
kubectl -n lab-02 rollout status deploy/storefront
```

## Prevention

- Pin images by digest (`nginx@sha256:...`) in production so a tag can't change
  under you, and so typos fail in CI rather than in the cluster.
- Have CI check that the image exists before deploying, e.g. `docker manifest inspect`
  or `crane digest`.
- Use a rolling update with `maxUnavailable: 0` so a bad image never takes down
  the pods that are already serving (scenario 12 shows this).

## Interview talking point

"ImagePullBackOff is a pull problem, not an app problem, so I go straight to pod
events. The error text tells me whether it's the tag, auth, rate limiting, network
or architecture, and each has a different fix."
