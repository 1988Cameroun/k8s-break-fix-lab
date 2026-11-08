## Hint 1

The pods never get as far as running your code, so there are no app logs to read.
The cluster's own record is in the pod **events**:

    kubectl -n lab-02 describe pod -l app=storefront

## Hint 2

Look at the `Failed to pull image` event. "not found" and "unauthorized" mean very
different things. Which one is it? Then read the image tag very carefully.

## Hint 3

`1.72` is not `1.27`. Update the image with:

    kubectl -n lab-02 set image deploy/storefront nginx=<correct-image>
