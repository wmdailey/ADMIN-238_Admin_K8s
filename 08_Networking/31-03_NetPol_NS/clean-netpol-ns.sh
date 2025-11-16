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

# Title: clean-netpol-ns.sh
# Author: WKD
# Version: 3.2.0
# Date: 17JUN25

# DEBUG
#set -x
#set -eu
#set >> /tmp/setvar.txt

# VARIABLE

# MAIN
kubectl -n prd-ns delete pods app01-pod
kubectl -n db-ns delete pods db01-pod
kubectl -n dev-ns delete pods web01-pod
kubectl -n default delete pods bak01-pod
kubectl -n prd-ns delete svc app01-svc
kubectl -n db-ns delete svc db01-svc
kubectl -n dev-ns delete svc web01-svc 
kubectl -n default delete svc bak01-svc
kubectl -n prd-ns delete netpol app01-netpol
kubectl -n db-ns delete netpol db01-netpol
kubectl delete ns prd-ns db-ns dev-ns

echo "Finished"
