# k8s-break-fix-lab

[![ci](https://github.com/1988Cameroun/k8s-break-fix-lab/actions/workflows/ci.yaml/badge.svg)](https://github.com/1988Cameroun/k8s-break-fix-lab/actions/workflows/ci.yaml)
![Kubernetes](https://img.shields.io/badge/kubernetes-kind-326CE5?logo=kubernetes&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-green)

**Break a Kubernetes cluster on purpose, then fix it.**

Twelve realistic incidents that you deploy into a local [kind](https://kind.sigs.k8s.io/)
cluster with one command. Each one comes with a ticket describing the symptom, three
progressive hints, an automated check that tells you when it's really fixed, and a
write-up of the root cause, the diagnosis and how to prevent it.

Debugging is the skill that matters most when running Kubernetes, and the hardest one to
practise without a broken production cluster. This lab gives you broken clusters on demand.

```console
$ ./lab.sh start 04
==> Deploying scenario 04: Service with no endpoints

# 04 · Service with no endpoints
> The checkout pods are all Running and Ready. But every request to the checkout Service fails...

$ ./lab.sh check
==> Checking scenario 04: Service with no endpoints
  ✔ checkout Deployment is Available
  ✔ Service checkout has endpoints
  ✘ http://checkout returns the nginx welcome page

Not fixed yet. Keep digging, or run ./lab.sh hint.
```

## Scenarios

| # | Scenario | Level | You practise |
|---|---|---|---|
| 01 | [CrashLoopBackOff: the missing config file](scenarios/01-crashloop-config) | easy | `logs --previous`, exit codes, ConfigMap volumes |
| 02 | [ImagePullBackOff: the version that doesn't exist](scenarios/02-imagepull-backoff) | easy | Pod events, image pull failure causes |
| 03 | [Pending: requests no node can satisfy](scenarios/03-pending-resources) | easy | Scheduler messages, requests vs limits, QoS |
| 04 | [Service with no endpoints](scenarios/04-service-no-endpoints) | medium | Selectors, EndpointSlices, `targetPort` |
| 05 | [Running but never Ready: a failing probe](scenarios/05-readiness-probe) | easy | Readiness vs liveness vs startup probes |
| 06 | [OOMKilled: the memory limit is too small](scenarios/06-oomkilled) | medium | Exit 137, cgroup limits, OOM vs eviction |
| 07 | [DNS: "bad address" across namespaces](scenarios/07-dns-cross-namespace) | medium | `resolv.conf`, search domains, `ndots`, CoreDNS |
| 08 | [NetworkPolicy: allow rule that allows nothing](scenarios/08-networkpolicy) | hard | Default deny, selectors, policy ports, least privilege |
| 09 | [PVC stuck Pending: the missing StorageClass](scenarios/09-pvc-pending) | medium | PVC → StorageClass, immutable fields, reclaim policy |
| 10 | [RBAC: 403 Forbidden from the API server](scenarios/10-rbac-forbidden) | hard | Roles, bindings, `auth can-i --as`, least privilege |
| 11 | [CreateContainerConfigError: secret and config refs](scenarios/11-create-container-config-error) | medium | Secret/ConfigMap references, one-error-at-a-time debugging |
| 12 | [Stuck rollout: a bad release, half deployed](scenarios/12-rollout-stuck) | medium | ReplicaSets, `maxUnavailable`, progress deadlines, `rollout undo` |

Several scenarios have **more than one bug** and **rules** against the shortcut "fix"
(deleting the probe, removing the default-deny policy, granting cluster-admin). The
checks enforce those rules, so a fix only passes if it's one you could ship.

## Quick start

### Option A: in your browser (GitHub Codespaces)

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/1988Cameroun/k8s-break-fix-lab)

Nothing to install. The Codespace comes with Docker, kind and kubectl ready. Once the
terminal opens, run `./lab.sh up`, then follow the commands below. **Stop the Codespace
when you finish** so it doesn't keep using your free monthly hours.

### Option B: on your own machine

**Requirements:** Docker, [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
v0.25+, `kubectl`, bash. Works on Linux, macOS and Windows (WSL2), on amd64 and arm64.

```bash
git clone https://github.com/1988Cameroun/k8s-break-fix-lab.git
cd k8s-break-fix-lab

./lab.sh up          # create a 3-node kind cluster (1 control plane, 2 workers)
./lab.sh list        # see all scenarios and your progress
./lab.sh start 01    # break something
# ...investigate and fix it with kubectl...
./lab.sh check       # did you fix it?
./lab.sh hint        # stuck? hints get more specific each time
./lab.sh solution    # the full write-up (after you've tried!)
./lab.sh down        # delete the cluster when you're done
```

`lab.sh` only works against the `kind-k8s-lab` context, so it can never touch a real
cluster by accident.

## How it works

```
scenarios/04-service-no-endpoints/
├── README.md          the ticket: symptom, goal, rules
├── scenario.conf      title, difficulty, namespaces
├── manifests.yaml     the broken state
├── setup.sh           (optional) extra steps, e.g. pushing a bad release
├── hints.md           three hints, from nudge to near-answer
├── verify.sh          automated checks: fixed AND rules respected
├── SOLUTION.md        root cause, diagnosis, fix, prevention, interview talking point
└── .solution/fix.sh   reference fix, used by CI
```

### Every scenario is tested in CI

On each push, GitHub Actions spins up a fresh kind cluster **per scenario** (12 in
parallel) and checks both directions:

1. Deploy the broken state → `verify.sh` must **fail**.
2. Apply the reference fix → `verify.sh` must **pass**.

So every scenario is really broken, and really fixable. The pipeline also runs
ShellCheck on every script and validates every manifest against the Kubernetes schema
with kubeconform.

## Design decisions

- **kind over minikube or k3d:** multi-node clusters in Docker, start in about a minute,
  the de facto standard for testing Kubernetes in CI, and its default CNI (kindnet)
  enforces NetworkPolicy.
- **Plain manifests, no Helm:** the bugs should be visible in the YAML. Templating would
  hide them behind another layer.
- **Tiny images (busybox, nginx, curl, python-alpine):** fast pulls, multi-arch, nothing
  to build.
- **Checks verify outcomes, not exact YAML:** there's usually more than one valid fix
  (`targetPort: 80` or `targetPort: http`, rollback or roll forward). The checks accept
  any fix that works and respects the rules.
- **One namespace per scenario:** reset is just deleting the namespace, and scenarios
  don't interfere with each other.

## The method

[`docs/troubleshooting-playbook.md`](docs/troubleshooting-playbook.md) condenses the
approach used across all scenarios: a status → first-command table, exit codes, the
network path hop by hop, and how to fix like it's production.

## Adding a scenario

1. Copy an existing scenario folder and give it the next number.
2. Write the broken `manifests.yaml`, the ticket, hints and `SOLUTION.md`.
3. Write `verify.sh` with `check` / `check_not` lines (see `lib/verify.sh`).
4. Write `.solution/fix.sh` and add the number to the CI matrix.
5. CI proves it's broken before the fix and passes after.

## Roadmap

- [ ] Node `NotReady` (stopped kubelet on a kind node)
- [ ] Taints and tolerations / node affinity scheduling failures
- [ ] Egress default-deny that breaks DNS
- [ ] HPA not scaling (missing metrics-server / requests)
- [ ] Ingress / Gateway API routing failures
- [ ] Expired certificate and admission webhook failures

## License

MIT
