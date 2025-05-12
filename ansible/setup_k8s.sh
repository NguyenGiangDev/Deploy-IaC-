#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "❌ Hãy chạy script với quyền sudo."
  exit 1
fi

if [ $# -ne 1 ]; then
    echo "Usage: sudo ./setup_k8s.sh [master|worker]"
    exit 1
fi

NODE_TYPE=$1

# Disable swap
swapoff -a
sed -i.bak '/\bswap\b/ s/^/#/' /etc/fstab

# Kernel modules & sysctl
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system

# Install Docker
apt-get remove -y docker docker-engine docker.io containerd runc
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

if docker ps >/dev/null 2>&1; then
  echo "✅ Docker Installed."
else
  echo "❌ Docker Installation failed."
  exit 1
fi

# Containerd
if [ -f /etc/containerd/config.toml ]; then
    containerd config default | tee /etc/containerd/config.toml
    sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
fi
systemctl restart containerd

# Kubernetes
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' > /etc/apt/sources.list.d/kubernetes.list

apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

systemctl daemon-reexec
systemctl restart kubelet

echo "✅ Kubernetes components installed."

if [ "$NODE_TYPE" == "master" ]; then
    user_ip=$(hostname -I | awk '{print $1}')
    kubeadm init --pod-network-cidr=10.32.0.0/16 --apiserver-advertise-address=$user_ip --ignore-preflight-errors=all

    # Install Weave Net
    export KUBECONFIG=/etc/kubernetes/admin.conf
    kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml

    echo "✅ Master node initialized."
else
    echo "✅ Worker node ready. Will join later using join command."
fi
