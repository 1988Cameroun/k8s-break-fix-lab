## Hint 1

Look at the rollout from the Deployment's point of view, then at its ReplicaSets:

    kubectl -n lab-12 rollout status deploy/web
    kubectl -n lab-12 get rs -l app=web
    kubectl -n lab-12 get pods -l app=web

How many pods come from the old ReplicaSet, and how many from the new one?

## Hint 2

Why are the new pods failing? And what does `maxUnavailable: 0` mean for the old ones?

    kubectl -n lab-12 describe deploy web | grep -A3 -i strategy
    kubectl -n lab-12 describe pod -l app=web | grep -i -A2 "failed"

## Hint 3

The quickest safe recovery is to go back to the last good revision:

    kubectl -n lab-12 rollout history deploy/web
    kubectl -n lab-12 rollout undo deploy/web

(Fixing the image tag forward also works.)
