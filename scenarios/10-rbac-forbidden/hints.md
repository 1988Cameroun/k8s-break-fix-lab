## Hint 1

Read the 403 message. The API server tells you exactly **who** was refused, **what
verb**, on **which resource**, in **which namespace**:

    kubectl -n lab-10 logs deploy/pod-watcher

## Hint 2

You can ask the API server the same question yourself by impersonating the
ServiceAccount:

    kubectl auth can-i list pods -n lab-10 --as=system:serviceaccount:lab-10:pod-watcher
    kubectl auth can-i get  pods -n lab-10 --as=system:serviceaccount:lab-10:pod-watcher

## Hint 3

The binding is fine. The Role allows `get` (one pod by name), but the app calls the
**collection** endpoint, which is the `list` verb. Add only the verb it needs:

    kubectl -n lab-10 edit role pod-reader
