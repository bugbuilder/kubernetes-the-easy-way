#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

SCRIPT_PATH=$(dirname "$(readlink -f "$BASH_SOURCE")")

cd $SCRIPT_PATH

TMP_ROOT=$SCRIPT_PATH/_tmp
TMP_CSR=$TMP_ROOT/csr

mkdir -p $TMP_CSR
cd $TMP_CSR

CERTS=$SCRIPT_PATH/../certs
mkdir -p $CERTS

CONTROLLER_COUNT=$(vagrant global-status | grep controller | wc -l)
WORKER_COUNT=$(vagrant global-status | grep worker | wc -l)
API_SERVER_CLUSTER_IP="10.32.0.1"

cleanup() {
  rm -rf $TMP_ROOT
}

csr() {
echo -e "\033[1mCertificate Signing Request: \033[32m${1}\033[0m"
cat > $1-csr.json <<EOF
{
  "CN": "$2",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "$3",
      "OU": "CA",
      "ST": "Oregon"
    }
  ]
}
EOF
}

genCert(){
echo -e "\033[1mGencert: \033[32m${1}\033[0m"
cfssl gencert \
	-config $SCRIPT_PATH/ca-config.json \
  	-ca=ca.pem \
  	-ca-key=ca-key.pem \
  	-profile=kubernetes \
	${2:+ -hostname=$2} \
  	$1-csr.json | cfssljson -bare $1

cp $1-key.pem $1.pem $CERTS
}

trap cleanup EXIT SIGINT

csr "ca" "Kubernetes" "Kubernetes"

cfssl gencert \
	-config $SCRIPT_PATH/ca-config.json \
	-initca ca-csr.json | cfssljson -bare ca

csr "admin" "admin" "system:masters"
csr "kube-controller-manager" "system:kube-controller-manager" "system:kube-controller-manager"
csr "kube-proxy" "system:kube-proxy" "system:node-proxier"
csr "kube-scheduler" "system:kube-scheduler" "system:kube-scheduler"
csr "service-accounts" "service-accounts" "Kubernetes"

genCert "admin"
genCert "kube-controller-manager"
genCert "kube-proxy"
genCert "kube-scheduler"
genCert "service-accounts"

for i in $(seq 1 $WORKER_COUNT) ; do
	instance="worker-$i"

	cd $SCRIPT_PATH/../cluster
	internal_ip=$(vagrant ssh $instance -c "hostname -I | cut -d' ' -f2" 2>/dev/null)
	cd $TMP_CSR

	csr "$instance" "system:node:$instance" "system:nodes"

	genCert $instance $internal_ip
done

cd $SCRIPT_PATH/../cluster

hostname="$API_SERVER_CLUSTER_IP,127.0.0.1,kubernetes.default"
for i in $(seq 1 $CONTROLLER_COUNT) ; do
	instance="controller-$i"
	internal_ip="$(vagrant ssh $instance -c "hostname -I | cut -d' ' -f2" 2>/dev/null)"
	hostname="$hostname,$internal_ip"
done < <(echo $hostname)

cd $TMP_CSR

csr "kubernetes" "Kubernetes" "Kubernetes"
genCert "kubernetes" $hostname
