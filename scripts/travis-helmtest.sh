#!/bin/bash
set -e

# This script will be used by travis to run functional test
# against different kuberentes version
export KUBE_VERSION=$1
sudo scripts/minikube.sh up
sudo scripts/minikube.sh deploy-rook
sudo scripts/minikube.sh create-block-pool
# pull docker images to speed up e2e
sudo scripts/minikube.sh cephcsi
sudo scripts/minikube.sh k8s-sidecar
sudo chown -R travis: "$HOME"/.minikube /usr/local/bin/kubectl

NAMESPACE=cephcsi-e2e-$RANDOM
# create ns for e2e
kubectl create ns ${NAMESPACE}
# delete snapshot CRD created by ceph-csi in rook
scripts/install-snapshot.sh delete-crd
# install snapshot controller
scripts/install-snapshot.sh install
# set up helm
scripts/install-helm.sh up
# install cephcsi helm charts
scripts/install-helm.sh install-cephcsi ${NAMESPACE}
# functional tests
go test github.com/ceph/ceph-csi/e2e -mod=vendor --deploy-timeout=10 -timeout=30m --cephcsi-namespace=${NAMESPACE} --deploy-cephfs=false --deploy-rbd=false -v

#cleanup
scripts/install-snapshot.sh cleanup
scripts/install-helm.sh cleanup-cephcsi ${NAMESPACE}
scripts/install-helm.sh clean
kubectl delete ns ${NAMESPACE}
sudo scripts/minikube.sh clean