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
