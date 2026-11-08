# 03 · Pending: requests no node can satisfy

**Level:** easy · **Namespace:** `lab-03`

## The ticket

> We copied the `report-generator` manifest from the production repo into dev.
> The pods have been `Pending` for an hour. There are no errors in the app logs
> (there are no app logs at all).

## Your goal

- `report-generator` runs 2 Available replicas in the dev cluster.

## Rules

- Team policy: every container must keep **both** CPU/memory **requests and limits**.
  Right-size them; don't delete them.
- Don't add nodes. The workload is a light batch job in dev.
