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

# Title: autoscaler_reporter.sh
# Author: WKD 
# Description: Queries Kubernetes to report the status of a specified autoscaler (HPA or VPA)
# and the resource usage of pods (via kubectl top pods) in a specified namespace.
# Usage: ./k8s_autoscaler_reporter.sh --namespace <NAMESPACE> --type <hpa|vpa>
# This script runs indefinitely, reporting at a specified interval.

# --- Configuration ---
SLEEP_TIME=5 # Sleep time in seconds between reports

# --- Variables for options namespace ---
NAMESPACE=""
AUTOSCALER_TYPE=""

# --- Functions ---

# Function to display the help menu
display_help() {
    echo "Usage: $0 --namespace <NAMESPACE> --type <hpa|vpa>"
    echo ""
    echo "Options:"
    echo "  --namespace <name>   The namespace to monitor."
    echo "  --type <hpa|vpa>     The type of autoscaler to report on."
    echo "  --help               Display this help message."
    echo ""
    echo "Examples:"
    echo "  $0 --namespace my-app --type hpa"
    echo "  $0 --namespace default --type vpa"
    exit 0
}

# Function to parse command-line arguments and validate input
parse_arguments() {
    # If no arguments are provided, show help
    if [ "$#" -eq 0 ]; then
        display_help
    fi

    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --namespace)
                if [ -n "$2" ]; then
                    NAMESPACE="$2"
                    shift 2
                else
                    echo "Error: --namespace requires a value." >&2
                    exit 1
                fi
                ;;
            --type)
                if [ "$2" == "hpa" ] || [ "$2" == "vpa" ]; then
                    AUTOSCALER_TYPE="$2"
                    shift 2
                else
                    echo "Error: --type must be 'hpa' or 'vpa'." >&2
                    exit 1
                fi
                ;;
            --help)
                display_help
                ;;
            *)
                echo "Error: Unknown option: $1" >&2
                display_help
                ;;
        esac
    done

    # Final validation of required arguments
    if [ -z "$NAMESPACE" ] || [ -z "$AUTOSCALER_TYPE" ]; then
        echo "Error: Both --namespace and --type are required." >&2
        display_help
    fi
}

# Function to check if the required kubectl command is installed
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        echo "Error: 'kubectl' command not found. Please ensure Kubernetes tools are installed and in your PATH." >&2
        exit 1
    fi
}

# Function to report the autoscaler status based on type
report_autoscaler_status() {
    if [ "$AUTOSCALER_TYPE" == "hpa" ]; then
        echo "--- HPA STATUS REPORT ---"
        AUTOSCALER_OUTPUT=$(kubectl get hpa -n "$NAMESPACE" 2>/dev/null)
        if [ -z "$AUTOSCALER_OUTPUT" ]; then
            echo "No Horizontal Pod Autoscalers (HPA) found in namespace '$NAMESPACE'."
        else
            echo "$AUTOSCALER_OUTPUT"
        fi
    elif [ "$AUTOSCALER_TYPE" == "vpa" ]; then
        echo "--- VPA STATUS REPORT ---"
        AUTOSCALER_OUTPUT=$(kubectl get vpa -n "$NAMESPACE" 2>/dev/null)
        if [ -z "$AUTOSCALER_OUTPUT" ]; then
            echo "No Vertical Pod Autoscalers (VPA) found in namespace '$NAMESPACE'."
        else
            echo "$AUTOSCALER_OUTPUT"
        fi
    fi
}

# Function to report the pod resource usage (CPU/Memory)
report_pod_metrics() {
    echo "--- POD RESOURCE METRICS ---"
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
parse_arguments "$@"
check_kubectl

while true; do
    report_autoscaler_status
    echo ""
    report_pod_metrics

    echo ""
    echo "Sleeping for $SLEEP_TIME seconds before next iteration..."
    echo "-----------------------------"
    echo ""

    sleep "$SLEEP_TIME"
done
