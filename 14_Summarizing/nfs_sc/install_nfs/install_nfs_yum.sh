#!/bin/bash

# Copyright 2025 Cloudera, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Disclaimer
# This script is for training purposes only and is to be used only
# in support of approved training. The author assumes no liability
# for use outside of a training environments. Unless required by
# applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, either express or implied.

# Title: install_nfs_yum.sh
# Author: WKD
# Date: 1MAY25

# DEBUG
#set -x
#set -eu
#set >> /tmp/setvar.txt

# Variables
NFS_SHARE="/svc/nfs/kubedata"

# Main
echo "Update and Install NFS Package"
sudo dnf update -y  
sudo dnf install -y nfs-utils

echo "Create NFS Share"
sudo mkdir -p /svc/nfs/kubedata
sudo chmod -R 777 $NFS_SHARE 
#sudo chown nobody:nogroup $NFS_SHARE
echo "/nfs-share  localhost.example.com(rw)" | sudo tee -a /etc/exports > /dev/null

#echo "Set Firewall Rules"
#sudo firewall-cmd --permanent --zone=public --add-service=nfs
#sudo firewall-cmd --reload
#sudo firewall-cmd --list-all

echo "Start NFS"
sudo systemctl enable nfs-server
sudo systemctl start nfs-server

echo "Test NFS"
showmount -e
mkdir ~/nfs-mount
mount prd01-worker:/svc/nfs/kubedata  ~/nfs-mount
echo "Test NFS" >> ~/nfs-mount/test.txt

sudo ls $NFS_SHARE
