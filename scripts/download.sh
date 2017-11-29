#!/bin/bash

BINARY_OUTPUT_DIR="binaries/"

ETCD_VERSION="v3.2.10"
ETCD_OUTPUT_DIR="${BINARY_OUTPUT_DIR}etcd/"
ETCD_BINARY_NAME="etcd.tar.gz"

CFSSL_OUTPUT_DIR="${BINARY_OUTPUT_DIR}cfssl/"
CFSSL_DOWNLOAD_PATH="https://pkg.cfssl.org/R1.2/"

KUBERNETES_VERSION="v1.8.4"
KUBERNETES_OUTPUT_DIR="${BINARY_OUTPUT_DIR}kubernetes/"
KUBERNETES_DOWNLOAD_PATH="https://storage.googleapis.com/kubernetes-release/release/$KUBERNETES_VERSION/bin/linux/amd64/"

DOCKER_VERSION="17.09.0"
DOCKER_OUTPUT_DIR="${BINARY_OUTPUT_DIR}docker/"
DOCKER_BINARY_NAME="docker-ce.tgz"
DOCKER_DOWNLOAD_PATH="https://download.docker.com/linux/static/stable/x86_64/"

CNI_PLUGIN_VERSION=v0.6.0
CNI_PLUGIN_OUTPUT_DIR="${BINARY_OUTPUT_DIR}cni/"
CNI_PLUGIN_BINARY_NAME="cni.tgz"
CNI_PLUGIN_DOWNLOAD_PATH="https://github.com/containernetworking/plugins/releases/download/v0.6.0/"

if [ ! -f ${ETCD_OUTPUT_DIR}${ETCD_BINARY_NAME} ]; then
  curl -L --create-dirs "https://storage.googleapis.com/etcd/${ETCD_VERSION}/etcd-${ETCD_VERSION}-linux-amd64.tar.gz" -o "${ETCD_OUTPUT_DIR}${ETCD_BINARY_NAME}"
fi

for binary in cfssl_linux-amd64 cfssljson_linux-amd64; do
  if [ ! -f ${CFSSL_OUTPUT_DIR}${binary} ]; then
    curl -L --create-dirs "${CFSSL_DOWNLOAD_PATH}${binary}" -o "${CFSSL_OUTPUT_DIR}${binary}"
  fi
done

for binary in kube-apiserver kube-controller-manager kube-scheduler kubectl kube-proxy kubelet; do
  if [ ! -f ${KUBERNETES_OUTPUT_DIR}${binary} ]; then
    curl -L --create-dirs "${KUBERNETES_DOWNLOAD_PATH}${binary}" -o "${KUBERNETES_OUTPUT_DIR}${binary}"
  fi
done

if [ ! -f ${DOCKER_OUTPUT_DIR}${DOCKER_BINARY_NAME} ]; then
  curl -L --create-dirs "${DOCKER_DOWNLOAD_PATH}docker-${DOCKER_VERSION}-ce.tgz" -o "${DOCKER_OUTPUT_DIR}${DOCKER_BINARY_NAME}"
fi

if [ ! -f ${CNI_PLUGIN_OUTPUT_DIR}${CNI_PLUGIN_BINARY_NAME} ]; then
  curl -L --create-dirs "${CNI_PLUGIN_DOWNLOAD_PATH}cni-plugins-amd64-${CNI_PLUGIN_VERSION}.tgz" -o "${CNI_PLUGIN_OUTPUT_DIR}${CNI_PLUGIN_BINARY_NAME}"
fi

