#!/bin/bash
echo "🚀 Starting Kubernetes Pre-Flight Setup for RHEL/Oracle Linux..."

# 1. Disable swap memory
echo "➡️ Disabling swap..."
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# 2. Disable SELinux (Required for containers to access host filesystem)
echo "➡️ Setting SELinux to permissive..."
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# 3. Disable Firewalld (Highly recommended for lab environments)
echo "➡️ Disabling firewall..."
sudo systemctl disable --now firewalld

# 4. Load required kernel modules
echo "➡️ Loading kernel modules..."
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

# 5. Configure sysctl parameters
echo "➡️ Configuring sysctl..."
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system

# 6. Install containerd 
echo "➡️ Installing containerd..."
sudo dnf install -y containerd

# 7. Configure containerd to use the systemd cgroup driver
echo "➡️ Configuring containerd..."
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
sudo systemctl enable --now containerd

# 8. Add the Kubernetes YUM Repository (v1.33)
echo "➡️ Adding Kubernetes repository..."
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.33/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.33/rpm/repodata/repomd.xml.key
EOF

# 9. Install kubeadm, kubelet, and kubectl
echo "➡️ Installing Kubernetes tools..."
sudo dnf install -y kubelet kubeadm --disableexcludes=kubernetes

# Enable kubelet to start on boot
sudo systemctl enable --now kubelet

echo "✅ Pre-Flight Setup Complete! This VM is ready for Kubernetes."

