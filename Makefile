CHART_NAME ?= prow
CHART_VERSION ?= 0.0.0
CHART_DIST ?= $(CHART_NAME)/dist

KUBEVAL_OPTS ?= --strict --kubernetes-version 1.16.0 --ignore-missing-schemas

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
	./${CHART_NAME} | kubeval $(KUBEVAL_OPTS)	

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

.PHONY: install-npm-check-updates
install-npm-check-updates:
	npm install npm-check-updates

.PHONY: update-npm-dependencies
update-npm-dependencies: install-npm-check-updates
	ncu -u
	npm install