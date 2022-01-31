#!/usr/bin/env bash

msg() { echo -e "\e[32mINFO ---> $1\e[0m"; }
err() { echo -e "\e[31mERR ---> $1\e[0m" ; exit 1; }

check() { command -v $1 >/dev/null 2>&1 || err "$1 utility is required"; }

waitForK3s() {
	while true; do
		kubectl --kubeconfig=${PWD}/k3s-config get no > /dev/null 2>&1

		[[ $? == 0 ]] && break || echo "Waiting 2 seconds to k3s ready..."

		sleep 2

	done
}

check docker-compose
check kubectl
check envsubst
check ip

mkdir -p ${HOME}/.kube

export K3S_VERSION="v1.23.3"
export K3S_CLUSTER_SECRET=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

envsubst < docker-compose.yaml.tpl > docker-compose.yaml

msg "Starting docker-compose"
docker-compose up -d

waitForK3s

msg "Check if default admin exist"
kubectl --kubeconfig=${PWD}/k3s-config get clusterrolebinding default-admin > /dev/null 2>&1

[[ $? != 0 ]] && msg "Creating k3s admin" && kubectl --kubeconfig=${PWD}/k3s-config create clusterrolebinding default-admin --clusterrole cluster-admin --serviceaccount=default:default

msg "Creating/updating job cleaner"
kubectl --kubeconfig=${PWD}/k3s-config apply -f ${PWD}/jobs-cleaner.yaml

msg "Waiting the token..."

while true; do
    [[ -z ${TOKEN} ]] && TOKEN=$(kubectl --kubeconfig=${PWD}/k3s-config get secrets -o jsonpath="{.items[?(@.metadata.annotations['kubernetes\.io/service-account\.name']=='default')].data.token}"|base64 -d) || break
done
HOST_IP=$(ip route get 1 | awk '{for(i=1;i<=NF;i++)if($i=="src")print $(i+1)}')

msg "Use host and token to connect your On-prem to jobs:"
echo ""
echo url: https://${HOST_IP}:6443
echo ""
echo token: ${TOKEN} | tee k3s-token
echo ""

msg "Done"
