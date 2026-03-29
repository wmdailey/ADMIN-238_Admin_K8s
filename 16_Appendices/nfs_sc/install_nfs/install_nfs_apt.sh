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

# Title: install_nfs_apt.sh
# Author: WKD
# Date: 1MAY25

# DEBUG
#set -x
#set -eu
#set >> /tmp/setvar.txt

# Variables
NFS_SHARE="/src/nfs/kubedata"

# Main

export DEBIAN_FRONTEND=noninteractive

readonly NFS_SHARE="/srv/nfs/kubedata"

echo "  apt update"
 apt-get update -qq >/dev/null

if [[ $HOSTNAME == "prd01-control-plane" ]]; then
  echo "  install nfs server"
   apt-get install -y -qq nfs-kernel-server >/dev/null
  echo "  creating nfs exports"
   mkdir -p $NFS_SHARE
   chown nobody:nogroup $NFS_SHARE
   chmod 0777 $NFS_SHARE
  echo "$NFS_SHARE *(rw,sync,no_root_squash,no_subtree_check)" |  tee /etc/exports >/dev/null
   systemctl restart nfs-kernel-server
else
  echo "  install nfs common"
   apt-get install -y -qq nfs-common >/dev/null
fi
