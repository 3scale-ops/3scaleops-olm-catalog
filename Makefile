AUTH_TOKEN = $(shell curl -sH "Content-Type: application/json" -XPOST https://quay.io/cnr/api/v1/users/login -d '{"user": {"username": "${QUAY_USERNAME}", "password": "${QUAY_PASSWORD}"}}' | jq -r '.token')

OPERATORS = $(shell ls olm-catalog)
REPOSITORY = 3scaleops
NAME_SUFIX = threescale


$(addprefix olm-verify-package-,$(OPERATORS)):
	operator-courier --verbose verify --ui_validate_io olm-catalog/$(subst olm-verify-package-,,$@)

$(addprefix olm-push-package-,$(OPERATORS)):
	@[ -z $(RELEASE) ] && \
		echo "Release missing. Example: 'make olm-push-package-prometheus-exporter-operator RELEASE=0.2.1-1'" && \
		exit 1
	operator-courier --verbose push olm-catalog/$(subst olm-push-package-,,$@) $(REPOSITORY) $(subst olm-push-package-,,$@)-$(NAME_SUFIX) $(RELEASE) "$(AUTH_TOKEN)"