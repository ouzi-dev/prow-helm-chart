
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
	./prow-chart

.PHONY: lint
lint:
	helm lint ./prow-chart	