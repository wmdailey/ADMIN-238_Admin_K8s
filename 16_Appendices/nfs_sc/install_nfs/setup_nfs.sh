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

# Title: setup_nfs.sh
# Author: WKD
# Date: 17JUN25
# Purpose: Install the NFS server on the Control Plane and then the NFS 
# client on every worker node.

# DEBUG
#set -x
#set -eu
#set >> /tmp/setvar.txt


# VARIABLE
FILE=install_nfs_apt.sh
MASTER=prd01-control-plane
WORKER1=prd01-worker
WORKER2=prd01-worker2
WORKER3=prd01-worker3

# MAIN
function nfs_server() {
# Install NFS server
  docker cp $FILE $MASTER:/usr/local/bin
  echo "Install NFS on $MASTER"
  docker exec -u root $MASTER /usr/local/bin/$FILE
  
  result=$? 
  if [ $result -ne 0 ]; then
    echo "ERROR: Script failed"
  fi
}

function nfs_client() {
# Install NFS client on every worker
  for client in $WORKER1 $WORKER2 $WORKER3; do
     docker cp $FILE $client:/usr/local/bin
     echo "Install NFS on $client"
     docker exec -u root $client /usr/local/bin/$FILE

     result=$? 
     if [ $result -ne 0 ]; then
      echo "ERROR: Script failed on $client"
     fi
  done
}

function main() {
# Run
  nfs_server
  nfs_client
  echo "Finished"
}

#MAIN
main "$@"
exit 0
