OPERATOR_NAME = saas-operator
OPERATOR_VERSION = $(PROJECT_VERSION)

SOURCE_REPOSITORY = https://github.com/3scale/$(OPERATOR_NAME).git
OPERATOR_CSV_FILE = $(MANIFESTS_DST_DIR)/manifests/$(OPERATOR_NAME).clusterserviceversion.yaml

$(OPERATOR_NAME)-customize-bundle:

$(OPERATOR_NAME)-bundle-build: bundle-build

$(OPERATOR_NAME)-bundle-push: bundle-push

$(OPERATOR_NAME)-catalog-add: $(OPERATOR_NAME)-bundle-build $(OPERATOR_NAME)-bundle-push catalog-add