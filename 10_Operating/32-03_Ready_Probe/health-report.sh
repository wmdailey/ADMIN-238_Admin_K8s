#!/bin/bash
# Copyright 2025 Cloudera, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
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

# Title: health-report.sh
# Author: WKD
# Description: Runs a while loop to report on events from a Pod. This 
# is used to monitor the state of the application. 
# This script runs indefinitely, reporting at a specified interval.


# --- Configuration ---
REFRESH_INTERVAL=5 # Refresh output every 3 seconds
KUBECTL_CMD="kubectl"

# --- Argument Check ---

if [ -z "$1" ]; then
    echo "Usage: $0 <pod-name>"
    echo ""
    echo "Example: $KUBECTL_CMD get pods"
    echo "         $0 my-app-deployment-55d6778c77-f2l5s"
    exit 1
fi

POD_NAME="$1"

# --- Check if kubectl is available ---

if ! command -v "$KUBECTL_CMD" &> /dev/null; then
    echo "Error: '$KUBECTL_CMD' command not found."
    echo "Please ensure kubectl is installed and in your PATH."
    exit 1
fi

# --- Main Watch Loop (using while true) ---

echo "--- Watching Pod: $POD_NAME (Refresh: ${REFRESH_INTERVAL}s) ---"
echo "Press Ctrl+C to stop watching."

# Loop indefinitely to continuously execute the command and clear the screen
while true; do
    clear
    echo "--- Watching Pod: $POD_NAME (Refresh: ${REFRESH_INTERVAL}s) ---"
    
    # Execute the command, filter out lines containing "Successfully pulled image", 
    # and "Container image" (which often precedes the pull message).
    "$KUBECTL_CMD" describe pod "$POD_NAME" | grep -v "Successfully pulled image" | grep -v "Container image"
    
    # Wait for the specified interval before running the loop again
    sleep "$REFRESH_INTERVAL"
done

