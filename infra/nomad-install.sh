#!/bin/bash

# SCRIPT TO INSTALL NOMAD IN DEV MODE (TESTED ON UBUNTU)

# Prepare system, obtain Hashicorp GPG key, and add repo to package manager
sudo apt install -y wget curl lpg coreutils
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Update the distribution, install Nomad, and verify that the command functions
sudo apt-get update -y
sudo apt-get install -y nomad
echo $(nomad --version)

# Enable the CNI drivers for Nomad / Docker / Consul on Ubuntu
curl -L -o cni-plugins.tgz "https://github.com/containernetworking/plugins/releases/download/v1.0.0/cni-plugins-linux-$( [ $(uname -m) = aarch64 ] && echo arm64 || echo amd64)"-v1.0.0.tgz && \
  sudo mkdir -p /opt/cni/bin && \
  sudo tar -C /opt/cni/bin -xzf cni-plugins.tgz
sudo apt-get install -y consul-cni
echo 1 | sudo tee /proc/sys/net/bridge/bridge-nf-call-arptables && \
  echo 1 | sudo tee /proc/sys/net/bridge/bridge-nf-call-ip6tables && \
  echo 1 | sudo tee /proc/sys/net/bridge/bridge-nf-call-iptables

# To preserve the bridge networking you can edit /etc/sysctl.d/ as outlined under the manual Linux installation here: https://developer.hashicorp.com/nomad/docs/install
