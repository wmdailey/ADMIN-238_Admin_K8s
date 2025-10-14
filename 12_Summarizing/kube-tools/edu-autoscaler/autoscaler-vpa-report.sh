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

# Title: scale-test-report.sh
# Author: WKD
# Description: Queries Kubernetes to report the status of all Vertical Pod Autoscalers (VPAs)
# and the resource usage of pods (via kubectl top pods) in a specified namespace.
# Usage: ./k8s_status_reporter.sh <NAMESPACE>
# This script runs indefinitely, reporting at a specified interval.

# --- Configuration ---
NAMESPACE=$1
SLEEP_TIME=5 # Sleep time in seconds between reports

# --- Functions ---

# Function to check if the required namespace argument was provided
check_arguments() {
    if [ -z "$NAMESPACE" ]; then
        echo "Error: Please provide a namespace name." >&2
        echo "Usage: $0 <NAMESPACE>" >&2
        exit 1
    fi

    # Optional: Basic check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        echo "Error: 'kubectl' command not found. Please ensure Kubernetes tools are installed and in your PATH." >&2
        exit 1
    fi
}

# Function to report the VPA status
report_vpa_status() {
    # Run kubectl get vpa and filter out errors if namespace is invalid/empty
    VPA_OUTPUT=$(kubectl get vpa -n "$NAMESPACE" 2>/dev/null)

    if [ -z "$VPA_OUTPUT" ]; then
        echo "No Vertical Pod Autoscalers (VPA) found in this namespace."
    else
        echo "$VPA_OUTPUT"
    fi
}

# Function to report the pod resource usage (CPU/Memory)
report_pod_metrics() {
    # Run kubectl top pods to get current CPU and Memory usage
    # This requires Kubernetes Metrics Server to be running.
    POD_METRICS=$(kubectl top pods -n "$NAMESPACE" 2>/dev/null)

    if [ "$?" -ne 0 ]; then
        echo "Error: Could not retrieve pod metrics." >&2
        echo "Note: 'kubectl top pods' requires the Metrics Server to be running in your cluster."
    elif [ -z "$POD_METRICS" ]; then
        # Check if the namespace exists or is empty
        if kubectl get namespace "$NAMESPACE" &> /dev/null; then
            echo "No pod metrics available in namespace '$NAMESPACE' (Namespace may be empty or Metrics Server has not reported yet)."
        else
            echo "Error: Namespace '$NAMESPACE' does not exist or you do not have permission to view it." >&2
        fi
    else
        echo "$POD_METRICS"
    fi
}

# --- Main Execution ---
check_arguments

while true; do
    echo ""
    echo "--- AUTOSCALER REPORT ---"

    report_vpa_status
    echo ""
    report_pod_metrics

    echo ""
    echo "Sleeping for $SLEEP_TIME seconds before next iteration..."
    sleep "$SLEEP_TIME"
done
