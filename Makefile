VERSION ?= 0.0.0
HELM_EXPERIMENTAL_OCI ?= 1
export HELM_EXPERIMENTAL_OCI  

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

# from https://github.com/helm/helm/issues/5861 
# helm package mychart
# helm chart save mychart  gcr.io/my-gcp-project/mychart # creates metadata in local folder ~/.helm/registry/
# gcloud auth configure-docker # needed only once, adds some data in ~/.docker/config.json
# docker login gcr.io/my-gcp-project/mychart
# helm chart push  gcr.io/my-gcp-project/mychart
.PHONY: push
push: package
	helm chart save ./prow-chart gcr.io/ouzi-helm-charts/prow-chart:$(VERSION)
	docker login gcr.io/ouzi-helm-charts/prow-chart
	helm chart push gcr.io/ouzi-helm-charts/prow-chart:$(VERSION)

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