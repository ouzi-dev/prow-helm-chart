CHART_NAME ?= prow
CHART_VERSION ?= 0.0.0
CHART_DIST ?= $(CHART_NAME)/dist
HELM_REPO ?= gs://ouzi-helm-charts

.PHONY: setup
setup:
	helm plugin install https://github.com/hayorov/helm-gcs --version 0.2.1

.PHONY: init
init:
	helm gcs init $(HELM_REPO)
	helm repo add ouzi $(HELM_REPO)

.PHONY: clean
clean:
	rm -rf $(CHART_NAME)/charts

.PHONY: add-repos
add-repos:
	helm init --client-only
	helm repo add stable https://kubernetes-charts.storage.googleapis.com/
	helm repo add jetstack https://charts.jetstack.io

.PHONY: update-repos
update-repos:
	helm repo update

.PHONY: get-deps
get-deps: add-repos update-repos
	helm dependency update ./${CHART_NAME}

# does not work without explicitly specifying the api version
# see: https://github.com/helm/helm/issues/6505 
.PHONY: validate
validate: get-deps
	helm init --client-only
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
package: clean add-repos
	@helm package \
	--version=$(CHART_VERSION) \
	--dependency-update \
	--destination $(CHART_DIST) \
	./$(CHART_NAME)

# from https://github.com/helm/helm/issues/5861 
# helm package mychart
# helm chart save mychart  gcr.io/my-gcp-project/mychart # creates metadata in local folder ~/.helm/registry/
# gcloud auth configure-docker # needed only once, adds some data in ~/.docker/config.json
# docker login gcr.io/my-gcp-project/mychart
# helm chart push  gcr.io/my-gcp-project/mychart
.PHONY: push
push: 
	helm repo add ouzi $(HELM_REPO)
	helm gcs push $(CHART_DIST)/$(CHART_NAME)-$(CHART_VERSION).tgz ouzi
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