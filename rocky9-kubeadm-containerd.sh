#!/bin/bash

# Update dnf Repository
dnf clean all
dnf -y update

# Deactivating Swap
sed -i '/ swap /s/^/#/' /etc/fstab
mount -a # && reboot
swapoff -a

# Deactivating Firewall
systemctl stop firewalld
systemctl disable firewalld
systemctl mask --now firewalld

# Lowering Security Policies for Setup
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# Config Network and IpTables
modprobe overlay
modprobe br_netfilter

cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system

# Installing Container Runtime: ContainerD
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
dnf install -y containerd.io
containerd config default | tee /etc/containerd/config.toml
sed -i "s/SystemdCgroup = false/SystemdCgroup = true/g"  /etc/containerd/config.toml
sed -i "s/disabled_plugin/enabled_plugin/g"  /etc/containerd/config.toml
systemctl enable --now containerd

# Installing Kubelet, Kubeadm and Kubectl
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl
EOF

dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
systemctl enable --now kubelet

# Only in the Control Plane (Master):
# kubeadm init phase certs ca
# kubeadm init phase kubeconfig admin
# kubeadm init --pod-network-cidr=192.168.0.0/16
# export KUBECONFIG=/etc/kubernetes/admin.conf

# kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/tigera-operator.yaml
# kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/custom-resources.yaml

# watch kubectl get pods --all-namespaces
