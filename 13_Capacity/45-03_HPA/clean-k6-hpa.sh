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

# Title: clean-k6.sh
# Author: WKD
# Version: 3.2.0
# Date: 17JUN25
# Purpose: Clean out the ingress controller that was installed manually.
# action menu option.

# DEBUG
#set -x
#set -eu
#set >> /tmp/setvar.txt


# VARIABLE

# MAIN
kubectl delete deploy perf-test-deploy 
kubectl delete svc perf-test 
kubectl delete hpa perf-test-hpa 
kubectl delete cm stress-test-cpu-cm stress-test-memory-cm 
kubectl delete job stress-test-cpu-job stress-test-memory-job 

echo "Finished"
