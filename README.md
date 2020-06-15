# prow-helm-chart <!-- omit in toc -->

Helmv3 chart to get Prow and everything needed up and running on Kubernetes.

- [Overview](#overview)
- [Install](#install)
  - [Using the ouzi helm repo](#using-the-ouzi-helm-repo)
  - [Using the GitHub Release](#using-the-github-release)
- [Requirements](#requirements)
- [Componenets](#componenets)
  - [Prow components](#prow-components)
- [Upgrading to a new release of Prow](#upgrading-to-a-new-release-of-prow)

## Overview 

This helm chart will install [Prow](https://github.com/kubernetes/test-infra/tree/master/prow) on Kubernetes.

## Install

### Using the Ouzi helm repo
```
helm repo add ouzi https://charts.ouzi.io
helm repo update
helm upgrade \
    prow \
		ouzi/prow \
		--version (PROW_CHART_VERSION) \
		--install \
		--wait \
		--atomic \
		--namespace prow \
		--values values.yaml
```

### Using the GitHub Release

The Helm package is published in the releases for easy install - no registry needed, just run the following command:

 ```
	@helm upgrade \
		prow \
		https://github.com/ouzi-dev/prow-helm-chart/releases/download/$(PROW_CHART_VERSION)/prow-$(PROW_CHART_VERSION).tgz \
		--install \
		--wait \
		--atomic \
		--namespace prow \
		--values values.yaml 	 
 ``` 

## Requirements

This chart is tested against a [GKE cluster](https://cloud.google.com/kubernetes-engine/) but any Kubernetes cluster >= 1.14 should work.
For help in setting up a GKE cluster for Prow, see our [prow-gke-terraform module](https://github.com/ouzi-dev/prow-gke-terraform)

The chart is developed using Helmv3 and we will not support any Helm v2

## Componenets

### Prow components

- [deck](https://github.com/kubernetes/test-infra/tree/master/prow/cmd/deck): Deck provides a UI for Prow, eg [ouzi-deck](https://prow.test-infra.ouzi.io).
  Deevelopers can see:
  - the current jobs running, the job status, and logs,
  - the PRs waiting to be merged including the missing checks preventing them to be merged,
  - the PRs history ie which were r were not previously merged ,
  - command help pages to find out which chatbot command to use,
  - plugin help pages to find out which plugins are configured and how to use them.
- [hook](https://github.com/kubernetes/test-infra/tree/master/prow/hook): Hook is responsible of receiving webhook calls from GitHub and handle the events. It is a stateless server that listens for GitHub webhooks and dispatches them to the appropriate plugins. Hook's plugins are used to trigger jobs, implement 'slash' commands, post to Slack, and more. See the prow/plugins directory for more information on plugins. Currently, hook, handles the following types of events from GitHub. Every other event is ignored:
  - issues
  - issue_comment
  - pull_request
  - pull_request_review
  - pull_request_review_comment
  - push
  - status 
- [plank](https://github.com/kubernetes/test-infra/tree/master/prow/plank): Plank is the controller that manages the job execution and lifecycle for jobs running on k8s  
- [crier](https://github.com/kubernetes/test-infra/tree/master/prow/crier): Crier is reposonsible for reporting the status of the ProwJobs. Currently, it supports:
  - [Gerrit Reporter](https://github.com/kubernetes/test-infra/blob/master/prow/gerrit/reporter)
  - [PubSub Reporter](https://github.com/kubernetes/test-infra/blob/master/prow/pubsub/reporter)
  - [GitHub Reporter](https://github.com/kubernetes/test-infra/blob/master/prow/github/reporter)
  - [Slack Reporter](https://github.com/kubernetes/test-infra/blob/master/prow/slack/reporter)
- [sinker](https://github.com/kubernetes/test-infra/tree/master/prow/cmd/sinker): Sinker cleans up old jobs and the pods backing them
- [horologium](https://github.com/kubernetes/test-infra/tree/master/prow/cmd/horologium): Triggers periodic jobs ie ProwJobs defined to run on a schedule 
- [tide](https://github.com/kubernetes/test-infra/blob/395658c487277aadab3904cfdbabfbddb0f2b034/prow/cmd/tide): Tide is responsible for the merging automation once they meet the defined criteria - see the [Tide Readme](https://github.com/kubernetes/test-infra/blob/master/prow/cmd/tide/README.md) for more info. It will automatically retest PRs that meet the criteria ("tide comes in") and automatically merge them when they have up-to-date passing test results ("tide goes out").
- [statusreconciler](https://github.com/kubernetes/test-infra/tree/master/prow/statusreconciler): Ensures that changes to required presubmits do not cause PRs in flight to get stuck in the merge queue
- [needs-rebase](https://github.com/kubernetes/test-infra/blob/master/prow/external-plugins/needs-rebase/plugin/plugin.go): Adds a label and blocks merging when rebase is needed
- [branchprotector](https://github.com/kubernetes/test-infra/tree/master/prow/cmd/branchprotector): A very useful component that configures [GithHub branch protection](https://help.github.com/articles/about-protected-branches/) for all repos/branches across the GitHub org. 
- [pushgateway](https://github.com/kubernetes/test-infra/blob/master/prow/metrics/README.md#pushgateway-and-proxy): Exposes all the metrics from the individual Prow components under a single scrape endpoint for Prometheus. This avoids having to configure Prometheus for each of the many Prow components. 
- [label-sync](https://github.com/kubernetes/test-infra/tree/master/label_sync): Reads a ConfigMap that contains GitHub labels(name, description, colour) and applies them to the managed GitHub org and its repos for a consistent view. eg a configmap would contain the following and label-sycn would apply it to all GitHub+ repos under management:
  ```
  labels:
  - color: 00ff00
    name: lgtm
  - color: ff0000
    name: priority/P0
    previously:
    - color: 0000ff
      name: P0
  - name: dead-label
    color: cccccc
    deleteAfter: 2017-01-01T13:00:00Z
  ```
- [ghproxy](https://github.com/kubernetes/test-infra/blob/master/ghproxy/README.md): A reverse proxy HTTP cache optimized for use with the GitHub API. ghProxy is designed to reduce API token usage by allowing many components to share a single [ghCache](https://github.com/kubernetes/test-infra/tree/master/ghproxy/ghcache)

## Upgrading to a new release of Prow

To upgrade to a new release of Prow, run `gcloud container images list-tags gcr.io/k8s-prow/plank --limit="10" --format='value(tags)' | grep -o -E 'v[^,]+'` to get the 10 most recent tags. Pick the latest and replace all image tags in the values.yaml. Do not forget to update the Chart.yaml appVersion.

You also need to check about deprecated flags in all of the components as well as changes with rbac.
