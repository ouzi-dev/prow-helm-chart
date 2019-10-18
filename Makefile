.PHONY: validate
validate:
	helm install prow --namespace prow --debug --dry-run ./prow-chart

.PHONY: lint
lint:
	helm lint ./prow-chart	