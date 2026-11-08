#!/usr/bin/env bash
# Installs kind and kubectl inside the dev container / Codespace.
set -euo pipefail

KIND_VERSION="v0.27.0"
KUBECTL_VERSION="v1.32.2"

case "$(uname -m)" in
  x86_64)  ARCH=amd64 ;;
  aarch64) ARCH=arm64 ;;
  *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

echo "Installing kind ${KIND_VERSION}..."
curl -fsSLo /tmp/kind "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-${ARCH}"
sudo install -m 0755 /tmp/kind /usr/local/bin/kind

echo "Installing kubectl ${KUBECTL_VERSION}..."
curl -fsSLo /tmp/kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl"
sudo install -m 0755 /tmp/kubectl /usr/local/bin/kubectl

# Short alias, like most Kubernetes engineers use.
grep -q "alias k=kubectl" ~/.bashrc || cat >>~/.bashrc <<'EOF'
alias k=kubectl
source <(kubectl completion bash)
complete -o default -F __start_kubectl k
EOF

kind version
kubectl version --client
echo "Done. Run: ./lab.sh up"
