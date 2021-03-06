#!/bin/bash
set -e

source data/config.bash

kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address="${KUBE_MASTER_IP}" --token="${KUBEADM_TOKEN}"

# By now the master node should be ready!
mkdir -p ~/.kube
ln -s /etc/kubernetes/admin.conf ~/.kube/config

# Install flannel
kubectl apply -f kube-flannel-rbac.yaml
kubectl apply -f kube-flannel.yaml

# Make master node a running worker node too!
# FIXME: Use taint tolerations instead in the future
kubectl taint nodes --all node-role.kubernetes.io/master-

# For now, just set up permissive RBAC rules.
# FIXME: Set up proper permissions instead!
kubectl create clusterrolebinding permissive-binding \
        --clusterrole=cluster-admin \
        --user=admin \
        --user=kubelet \
        --group=system:serviceaccounts

# Install helm
curl https://storage.googleapis.com/kubernetes-helm/helm-v2.4.2-linux-amd64.tar.gz | tar xvz
mv linux-amd64/helm /usr/local/bin
rm -rf linux-amd64

/usr/local/bin/helm init

# Wait for tiller to be ready!
# HACK: Do this better

sleep 1m

# Install nginx and other support stuff!
helm install --name=support --namespace=support support/
