# quay.io/3scaleops OLM catalog management

## Repo's directory structure

Each operator's package manifests must be in a directory named after the operator' name inside `olm-catalog`. Inside each operator's directory the package file needs to be present as well as a directory per operator version released to the catalog. Each version's directory must contain the ClusterServiceVersion file and the CRD definition files for the operator.

The file structure should be as follows:

```bash
olm-catalog
├── grafana-operator
│   ├── 3.5.0-1
│   │   ├── GrafanaDashboard.yaml
│   │   ├── GrafanaDataSource.yaml
│   │   ├── grafana-operator-threescale.v3.5.0-1.clusterserviceversion.yaml
│   │   └── Grafana.yaml
│   ├── 3.5.0-2
│   │   ├── GrafanaDashboard.yaml
│   │   ├── GrafanaDataSource.yaml
│   │   ├── grafana-operator-threescale.v3.5.0-2.clusterserviceversion.yaml
│   │   └── Grafana.yaml
│   └── grafana-operator-threescale.package.yaml
└── prometheus-exporter-operator
    ├── 0.2.1-1
    │   ├── monitoring.3scale.net_prometheusexporters_crd.yaml
    │   └── prometheus-exporter-operator-threescale.v0.2.1-1.clusterserviceversion.yaml
    └── prometheus-exporter-operator-threescale.package.yaml
```

When addind a new operator or a new release for an existent operator just follow the directory structure, the `Makefile` will take care of the rest for you.

## Customize the package manifests for an operator

1. Copy the CSV and CRDs of the operator release you want to modify. You can either copy them for the operator's github repo (if they are kept there) or even install the operator in a cluster and get the CSV and CRDs directly from the cluster.

2. Add the `-threescale` sufix to all file names, following the same directory structure already present.

3. Edit the package yaml file (with name `<operator-name>-threescale.package.yaml) and ensure the` and ensure the `name` has the `-threescale` sufix appended. Also modify the CSV version you want to update the given channel with.

4. Modify file/directory names with the version you just configured in the package file

5. Edit the CSV yaml file inside the given version's directory and change:
   1. `metadata.name` to `<operators-name>-threescale.v<version>`
   2. `spec.version` to `<version>`

6. Modify any other CSV field you need to. For example, in the case of the `grafana-operator` you need to change the `spec.installModes` to allow cluster wide installation.

## Versioning

With our internal catalog, we are modifing just the operator's packaging, not the operator itself. To reflect this use an extra number in the operators version to mark the packaging version of a given release. This ensures we can do some testing with packaging while correctly refelcting the operator version we are using.

For example we might have the `grafana-operator` at version `3.5.0` but release to different packages under `3.5.0-1` and then `3.5.0-2`.

## Pushing package manifests to OLM

* Validate package manifests are correct using `make olm-verify-package-<operator-name>`

```bash
▶ make olm-verify-package-prometheus-exporter-operator
operator-courier --verbose verify --ui_validate_io olm-catalog/prometheus-exporter-operator
INFO:operatorcourier.verified_manifest:The source directory is in nested structure.
INFO:operatorcourier.verified_manifest:Parsing version: 0.2.1-1
INFO: Validating bundle. []
INFO: Validating custom resource definitions. []
INFO: Evaluating crd prometheusexporters.monitoring.3scale.net [0.2.1-1/monitoring.3scale.net_prometheusexporters_crd.yaml]
INFO: Validating cluster service versions. [0.2.1-1/monitoring.3scale.net_prometheusexporters_crd.yaml]
INFO: Evaluating csv prometheus-exporter-operator-threescale.v0.2.1 [0.2.1-1/prometheus-exporter-operator-threescale.v0.2.1-1.clusterserviceversion.yaml]
INFO: Validating packages. [0.2.1-1/prometheus-exporter-operator-threescale.v0.2.1-1.clusterserviceversion.yaml]
INFO: Evaluating package prometheus-exporter-operator-threescale [prometheus-exporter-operator/prometheus-exporter-operator-threescale.package.yaml]
INFO: Validating cluster service versions for operatorhub.io UI. [prometheus-exporter-operator/prometheus-exporter-operator-threescale.package.yaml]
INFO: Evaluating csv prometheus-exporter-operator-threescale.v0.2.1 [prometheus-exporter-operator/prometheus-exporter-operator-threescale.package.yaml]
```

* Push package manifests to quay.io/3scaleops using `make olm-push-package-<operator-name> RELEASE=<version>`. You need to have your quay user and password exported as environment variables in `QUAY_USERNAME` and `QUAY_PASSWORD`.

```bash
▶ make olm-push-package-prometheus-exporter-operator RELEASE=0.2.1-1
operator-courier --verbose push olm-catalog/prometheus-exporter-operator 3scaleops prometheus-exporter-operator-threescale 0.2.1-1 "basic cm9pdmF6OjhhdGtPWnhpOGF0a09aeGk="
INFO:operatorcourier.verified_manifest:The source directory is in nested structure.
INFO:operatorcourier.verified_manifest:Parsing version: 0.2.1-1
INFO: Validating bundle. []
INFO: Validating custom resource definitions. []
INFO: Evaluating crd prometheusexporters.monitoring.3scale.net [0.2.1-1/monitoring.3scale.net_prometheusexporters_crd.yaml]
INFO: Validating cluster service versions. [0.2.1-1/monitoring.3scale.net_prometheusexporters_crd.yaml]
INFO: Evaluating csv prometheus-exporter-operator-threescale.v0.2.1 [0.2.1-1/prometheus-exporter-operator-threescale.v0.2.1-1.clusterserviceversion.yaml]
INFO: Validating packages. [0.2.1-1/prometheus-exporter-operator-threescale.v0.2.1-1.clusterserviceversion.yaml]
INFO: Evaluating package prometheus-exporter-operator-threescale [prometheus-exporter-operator/prometheus-exporter-operator-threescale.package.yaml]
INFO:operatorcourier.push:Generating 64 bit bundle and pushing to app registry.
INFO:operatorcourier.push:Pushing bundle to https://quay.io/cnr/api/v1/packages/3scaleops/prometheus-exporter-operator-threescale
DEBUG:urllib3.connectionpool:Starting new HTTPS connection (1): quay.io:443
DEBUG:urllib3.connectionpool:https://quay.io:443 "POST /cnr/api/v1/packages/3scaleops/prometheus-exporter-operator-threescale HTTP/1.1" 409 84
ERROR:operatorcourier.push:{"error":{"code":"package-exists","details":{},"message":"package exists already"}}
```
