version: '3'
services:
  control:
    restart: always
    image: rancher/k3s:${K3S_VERSION}
    command: server --disable-agent --no-deploy servicelb --no-deploy traefik
    environment:
    - K3S_CLUSTER_SECRET=${K3S_CLUSTER_SECRET}
    - K3S_KUBECONFIG_OUTPUT=/output/k3s-config
    - K3S_KUBECONFIG_MODE=666
    volumes:
    - k3s-control:/var/lib/rancher/k3s
    - ${PWD}:/output
    ports:
    - 6443:6443
    network_mode: "host"

  node:
    restart: always
    image: rancher/k3s:${K3S_VERSION}
    tmpfs:
    - /run
    - /var/run
    environment:
    - K3S_URL=https://localhost:6443
    - K3S_CLUSTER_SECRET=${K3S_CLUSTER_SECRET}
    privileged: true
    network_mode: "host"

volumes:
  k3s-control: {}
