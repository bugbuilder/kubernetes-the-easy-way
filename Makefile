.PHONY: provisioning-compute-resources
provisioning-compute-resources:
	@echo "+ $@"
	@./hack/instances-up.sh

.PHONY: provisioning-the-CA-and-generating-TLS-certificates
provisioning-the-CA-and-generating-TLS-certificates: provisioning-compute-resources
	@echo "+ $@"
	@./hack/gen-certs.sh

.PHONY: cleaning-up
cleaning-up:
	@echo "+ $@"
	@./hack/instances-destroy.sh

