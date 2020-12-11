AUTH_TOKEN = $(shell curl -sH "Content-Type: application/json" -XPOST https://quay.io/cnr/api/v1/users/login -d '{"user": {"username": "${QUAY_USERNAME}", "password": "${QUAY_PASSWORD}"}}' | jq -r '.token')

OPERATORS = $(shell ls olm-catalog)
APPREGISTRY = 3scaleops
NAME_SUFIX = threescale
OCP_VERSION = v4.5
CATALOG_RELEASE = latest


$(addprefix olm-verify-package-,$(OPERATORS)):
	operator-courier --verbose verify --ui_validate_io olm-catalog/$(subst olm-verify-package-,,$@)

$(addprefix olm-push-package-,$(OPERATORS)):
	@[ -z $(RELEASE) ] && \
		echo "Release missing. Example: 'make olm-push-package-prometheus-exporter-operator RELEASE=0.2.1-1'" && \
		exit 1 || true
	operator-courier --verbose push olm-catalog/$(subst olm-push-package-,,$@) $(APPREGISTRY) $(subst olm-push-package-,,$@)-$(NAME_SUFIX) $(RELEASE) "$(AUTH_TOKEN)"

build-catalog:
	@echo "IMPORTANT: you need to 'docker login registry.redhat.io' with your access.redhat.com login for the 3scale-saas account"
	@echo "IMPORTANT: you need to use openshift client version 4.4 or higher"
	oc adm catalog build \
		--appregistry-org $(APPREGISTRY) \
		--filter-by-os="linux/amd64" \
		--from=registry.redhat.io/openshift4/ose-operator-registry:$(OCP_VERSION) \
		--to=quay.io/3scaleops/olm-catalog:$(CATALOG_RELEASE)

########################
#### Bundle targets ####
########################

# find or download yq
# download yq if necessary
yq:
ifeq (, $(shell command -v yq 2> /dev/null))
	@GO111MODULE=off go get github.com/mikefarah/yq/v3
YQ=$(GOBIN)/yq
else
YQ=$(shell command -v yq 2> /dev/null)
endif

REGISTRY = quay.io/3scaleops
BUNDLE_CATALOG_DIR = olm-bundle-catalog
BUNDLE_CATALOG_IMG = $(REGISTRY)/olm-catalog:bundle
BASE_TMP_DIR = /tmp/3scaleops-olm-catalog
PROJECT_NAME = $(notdir $(basename $(SOURCE_REPOSITORY)))
TMP_DIR = $(BASE_TMP_DIR)/$(PROJECT_NAME)_$(PROJECT_VERSION)
MANIFESTS_DST_DIR = $(BUNDLE_CATALOG_DIR)/$(PROJECT_NAME)/$(PROJECT_VERSION)
BUNDLE_SUFFIX = threescale
BUNDLE_IMG = $(REGISTRY)/$(PROJECT_NAME)-$(BUNDLE_SUFFIX)-bundle:$(PROJECT_VERSION)

.PHONY: build-bundle-manifests
# Example: make bundle-build SOURCE_REPOSITORY=https://github.com/3scale/marin3r.git PROJECT_VERSION=v0.7.0-alpha5
bundle-manifests: clean
	git clone --depth 1 --branch $(PROJECT_VERSION) $(SOURCE_REPOSITORY) $(TMP_DIR) 2> /dev/null
	mkdir -p $(MANIFESTS_DST_DIR)
	cp -a $(TMP_DIR)/bundle/* $(MANIFESTS_DST_DIR)
	cp -a $(TMP_DIR)/bundle.Dockerfile $(MANIFESTS_DST_DIR)
	sed -E -i '' 's@bundle/@@' $(MANIFESTS_DST_DIR)/bundle.Dockerfile
	$(MAKE) $(PROJECT_NAME)-customize-bundle
	$(MAKE) clean

# Build the bundle image.
.PHONY: bundle-build
bundle-build:
	test -f $(MANIFESTS_DST_DIR)/manifests/$(PROJECT_NAME).clusterserviceversion.yaml || $(MAKE) bundle-manifests
	docker build -f $(MANIFESTS_DST_DIR)/bundle.Dockerfile -t $(BUNDLE_IMG) $(MANIFESTS_DST_DIR)

bundle-push:
	docker push $(BUNDLE_IMG)

catalog-add:
	opm index add \
		--build-tool docker \
		--mode replaces \
		--bundles $(BUNDLE_IMG) \
		--from-index $(BUNDLE_CATALOG_IMG) \
		--tag $(BUNDLE_CATALOG_IMG)
	docker push $(BUNDLE_CATALOG_IMG)

clean:
	rm -rf $(BASE_TMP_DIR)

include marin3r.mk
include saas-operator.mk