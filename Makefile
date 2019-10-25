VERSION ?= 0.0.0

.PHONY: clean
clean:
	rm -rf prow-charts/charts

.PHONY: add-repos
add-repos:
	helm repo add stable https://kubernetes-charts.storage.googleapis.com/
	helm repo add jetstack https://charts.jetstack.io

.PHONY: update-repos
update-repos:
	helm repo update

.PHONY: get-deps
get-deps: add-repos update-repos
	helm dependency update ./prow-chart

# does not work without explicitly specifying the api version
# see: https://github.com/helm/helm/issues/6505 
.PHONY: validate
validate: get-deps
	helm template prow \
	--namespace prow \
	--debug \
	-a apiregistration.k8s.io/v1beta1 \
	-a cert-manager.io/v1alpha2 \
	-a monitoring.coreos.com/v1 \
	-a apiextensions.k8s.io/v1beta1 \
	-a credstash.local/v1 \
	./prow-chart

.PHONY: package
package: clean get-deps
	@helm package \
	--version=$(VERSION) \
	--dependency-update \
	--destination dist/ \
	./prow-chart

.PHONY: lint
lint:
	helm lint ./prow-chart	

.PHONY: semantic-release
semantic-release:
	npm ci
	npx semantic-release

.PHONY: semantic-release-dry-run
semantic-release-dry-run:
	npm ci
	npx semantic-release -d