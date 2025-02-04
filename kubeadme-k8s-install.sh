#!/bin/bash

apt-get update

apt-get upgrade -y

apt install curl apt-transport-https git wget software-properties-common lsb-release ca-certificates socat -y

swapoff -a

modprobe overlay

modprobe br_netfilter

cat <<EOF | tee /etc/sysctl.d/kubernetes.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sysctl --system

# Install the necessary key for the software to install
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

#  Install the containerd software
apt-get update &&  apt-get install containerd.io -y
containerd config default | tee /etc/containerd/config.toml
sed -e 's/SystemdCgroup = false/SystemdCgroup = true/g' -i /etc/containerd/config.toml
sleep 3
cat /etc/containerd/config.toml | grep -i SystemdCgroup
systemctl restart containerd

# Download the public signing key for the Kubernetes package repositories
mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Add the appropriate Kubernetes apt repository.
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

apt-get update

# Install the Kubernetes software
apt-get install -y kubeadm=1.30.1-1.1 kubelet=1.30.1-1.1 kubectl=1.30.1-1.1

apt-mark hold kubelet kubeadm kubectl
