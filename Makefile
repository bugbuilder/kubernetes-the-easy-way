.PHONY: provisioning-compute-resources
provisioning-compute-resources:
	@echo "+ $@"
	@./hack/instances-up.sh

.PHONY: cleaning-up
cleaning-up:
	@echo "+ $@"
	@./hack/instances-destroy.sh

