MARIN3R_CSV_FILE = $(MANIFESTS_DST_DIR)/manifests/marin3r.clusterserviceversion.yaml
MARIN3R_VERSION = $(PROJECT_VERSION)

marin3r-customize-bundle: yq
	@echo "using BUNDLE_SUFFIX $(BUNDLE_SUFFIX)"
	$(YQ) w --inplace $(MARIN3R_CSV_FILE) metadata.name marin3r-$(BUNDLE_SUFFIX).$(MARIN3R_VERSION)
	$(YQ) w --inplace $(MARIN3R_CSV_FILE) spec.displayName "MARIN3R 3scale SaaS"
	$(YQ) w --inplace $(MARIN3R_CSV_FILE) spec.provider.name $(BUNDLE_SUFFIX)
	$(YQ) w --inplace $(MANIFESTS_DST_DIR)/metadata/annotations.yaml 'annotations."operators.operatorframework.io.bundle.package.v1"' marin3r-$(BUNDLE_SUFFIX)
	sed -E -i 's/(operators\.operatorframework\.io\.bundle\.package\.v1=).+/\1marin3r-$(BUNDLE_SUFFIX)/' $(MANIFESTS_DST_DIR)/bundle.Dockerfile
	# Modify "spec.replaces" if set
	-REPLACES=$(shell $(YQ) r $(MARIN3R_CSV_FILE) spec.replaces) && [ "$$REPLACES" != "" ] && \
		$(YQ) w --inplace $(MARIN3R_CSV_FILE) spec.replaces "$${REPLACES/marin3r/marin3r-$(BUNDLE_SUFFIX)}"

# Example: make marin3r-bundle-build PROJECT_VERSION=v0.7.0-alpha5
marin3r-bundle-build: export SOURCE_REPOSITORY = https://github.com/3scale/marin3r.git
marin3r-bundle-build: bundle-build

marin3r-bundle-push: export SOURCE_REPOSITORY = https://github.com/3scale/marin3r.git
marin3r-bundle-push: bundle-push

marin3r-catalog-add: export SOURCE_REPOSITORY = https://github.com/3scale/marin3r.git
marin3r-catalog-add: marin3r-bundle-build marin3r-bundle-push catalog-add