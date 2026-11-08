# 11 · CreateContainerConfigError: secret and config refs

**Level:** medium · **Namespace:** `lab-11`

## The ticket

> We moved the `payments` service's database password into a Secret and its settings
> into a ConfigMap, following the security review. The pods now show
> `CreateContainerConfigError` and never start.

## Your goal

- `payments` runs 2 Available replicas, reading `DB_PASSWORD` from the Secret and
  `LOG_LEVEL` from the ConfigMap.

## Rules

- The password must still come from the `payment-db` Secret. Don't paste it into the
  Deployment as a plain value.
- There may be more than one problem.
