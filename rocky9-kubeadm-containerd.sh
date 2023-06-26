#!/bin/bash

# Update dnf Repository

dnf clean all
dnf -y update

# Deactivating Swap and Firewall

swapoff -a
systemctl stop firewalld

# Installing Container Runtime: ContainerD

dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
dnf install -y containerd.io
containerd config default | tee /etc/containerd/config.toml
sed -i "s/SystemdCgroup = false/SystemdCgroup = true/g"  /etc/containerd/config.toml
sed -i "s/disabled_plugin/enabled_plugin/g"  /etc/containerd/config.toml
systemctl enable --now containerd

# Lowering Secutiry Policies for Setup

sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# Installing Kubelet, Kubeadm and Kubectl 

cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
sudo systemctl enable --now kubelet

# Fix some net problems in kubeadm init 

modprobe br_netfilter
sysctl -p /etc/sysctl.conf
echo 1 > /proc/sys/net/ipv4/ip_forward

# Init the kubeadm

kubeadm init
export KUBECONFIG=/etc/kubernetes/admin.conf