## Hint 1

When logs stop without an error, the process probably didn't exit by itself; it
was killed. Check how the last container ended:

    kubectl -n lab-06 describe pod -l app=image-resizer | grep -A5 "Last State"

## Hint 2

Exit code **137** is 128 + 9 (SIGKILL). With the reason `OOMKilled`, the kernel killed
the container for going over its memory **limit**. Compare the limit with what the
app needs:

    kubectl -n lab-06 get deploy image-resizer -o jsonpath='{.spec.template.spec.containers[0].resources}'

## Hint 3

The app needs ~150 MB plus the Python interpreter itself. Give the limit some
headroom (for example 256Mi) and set the request to match what it really uses:

    kubectl -n lab-06 set resources deploy/image-resizer --requests=memory=192Mi --limits=memory=256Mi
