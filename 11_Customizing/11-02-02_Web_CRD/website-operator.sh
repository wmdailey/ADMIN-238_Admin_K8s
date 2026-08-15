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

# Title: clean-website-crd.sh
# Author: WKD
# Exercise: 46-02
# Version: 3.3.0

# DEBUG
#set -x
#set -eu
#set >> /tmp/setvar.txt

echo "Starting Website Mirror Operator loop..."

while true; do
  # 1. OBSERVE: Look for any WebsiteMirror resources
  MIRRORS=$(kubectl get websitemirrors.stable.example.com -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)

  for MIRROR in $MIRRORS; do
    # Get the target URL specified in the custom resource
    TARGET_URL=$(kubectl get websitemirror $MIRROR -o jsonpath='{.spec.targetUrl}')
    
    # 2. ANALYZE: Check if a corresponding Nginx pod is already running
    POD_EXISTS=$(kubectl get pod -l app=$MIRROR -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)
    
    if [ -z "$POD_EXISTS" ]; then
      # 3. ACT: The pod doesn't exist, so create it to match the desired state
      echo "Found new mirror request: $MIRROR targeting $TARGET_URL. Deploying Nginx proxy..."
      
      # We spin up a pod configured to proxy to the target URL
      kubectl run $MIRROR --image=nginx --restart=Never --labels="app=$MIRROR" -- \
        bash -c "echo 'server { listen 80; location / { proxy_pass $TARGET_URL; } }' > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"
    fi
  done

  # Sleep for 5 seconds before checking again (the loop)
  sleep 5
done
