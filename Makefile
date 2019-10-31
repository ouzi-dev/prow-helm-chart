CHART_NAME ?= prow
CHART_VERSION ?= 0.0.0
CHART_DIST ?= $(CHART_NAME)/dist
HELM_REPO ?= gs://ouzi-helm-charts

.PHONY: clean
clean:
	rm -rf $(CHART_NAME)/charts

# does not work without explicitly specifying the api version
# see: https://github.com/helm/helm/issues/6505 
.PHONY: validate
validate: 
	helm template prow \
	--namespace prow \
	--debug \
	-a apiregistration.k8s.io/v1beta1 \
	-a cert-manager.io/v1alpha2 \
	-a monitoring.coreos.com/v1 \
	-a apiextensions.k8s.io/v1beta1 \
	-a credstash.local/v1 \
	./${CHART_NAME}

.PHONY: package
package: clean 
	@helm package \
	--version=$(CHART_VERSION) \
	--dependency-update \
	--destination $(CHART_DIST) \
	./$(CHART_NAME)

.PHONY: lint
lint:
	helm lint ./$(CHART_NAME)	

.PHONY: semantic-release
semantic-release:
	npm ci
	npx semantic-release

.PHONY: semantic-release-dry-run
semantic-release-dry-run:
	npm ci
	npx semantic-release -d