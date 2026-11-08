.PHONY: up down list lint help

help:
	@./lab.sh help

up:
	@./lab.sh up

down:
	@./lab.sh down

list:
	@./lab.sh list

# Same checks CI runs (needs shellcheck and docker for kubeconform).
lint:
	shellcheck lab.sh lib/*.sh .devcontainer/*.sh scenarios/*/*.sh scenarios/*/.solution/*.sh
	docker run --rm -v "$(CURDIR):/w" -w /w ghcr.io/yannh/kubeconform:latest \
		-strict -summary scenarios/*/manifests.yaml
