#!/bin/bash

# Update dnf Repository

dnf clean all
dnf -y update

# Deactivating Swap and Firewall

sudo sed -i '/ swap /s/^/#/' /etc/fstab
mount -a # && reboot
swapoff -a

systemctl stop firewalld
systemctl disable firewalld
systemctl mask --now firewalld

# Installing Container Runtime: ContainerD

dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
dnf install -y containerd.io
containerd config default | tee /etc/containerd/config.toml
sed -i "s/SystemdCgroup = false/SystemdCgroup = true/g"  /etc/containerd/config.toml
sed -i "s/disabled_plugin/enabled_plugin/g"  /etc/containerd/config.toml
systemctl enable --now containerd

# Lowering Security Policies for Setup

sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

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

sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
sudo systemctl enable --now kubelet

# Fix some net problems in kubeadm init 

modprobe br_netfilter
sysctl -p /etc/sysctl.conf
echo 1 > /proc/sys/net/ipv4/ip_forward

# Only in the Control Plane (Master):

# kubeadm init phase certs ca
# kubeadm init phase kubeconfig admin
# kubeadm init
# export KUBECONFIG=/etc/kubernetes/admin.conf

# kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/tigera-operator.yaml
# kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/custom-resources.yaml

# watch kubectl get pods -n kube-system
