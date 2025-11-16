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

# Title: clean-webstore.sh
# Author: WKD
# Version: 3.2.0
# Date: 17JUN25
# Purpose: Clean out the webstore

# DEBUG
#set -x
#set -eu
#set >> /tmp/setvar.txt

# VARIABLE

# MAIN
kubectl -n webstore-ns delete deploy webstore-app-deploy webstore-order-deploy webstore-video-deploy 
kubectl -n webstore-ns delete svc webstore-app-svc webstore-order-svc webstore-video-svc
kubectl -n webstore-ns delete cm webstore-app-cm  webstore-app-nginx-cm 
kubectl -n webstore-ns delete cm webstore-order-cm  webstore-order-nginx-cm 
kubectl -n webstore-ns delete cm webstore-video-cm  webstore-video-nginx-cm 
# kubectl -n webstore-ns delete ing webstore-ing
kubectl delete namespace webstore-ns 

echo "Finished"
