#!/bin/bash

# Copyright 2025 Cloudera, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
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

# Title: blue-green-test.sh
# Author: WKD
# Version: 3.5.2
# Date: 23OCT25 (Fixed bad substitution and EOF error)
# Description:
# Blue-Green deployment script with optional success/fail flag and custom monitoring time.
# Requires: jq (JSON processor) and curl.

# --- Default Variables ---
# Configuration Variables
NAMESPACE="dev-ns"
APP_NAME="webstore"
HOST_NAME="webstore.local"
BLUE_SVC="${APP_NAME}-blue-svc"
GREEN_SVC="${APP_NAME}-green-svc"
NEW_IMAGE_TAG="v2.0.0" # The image tag for the Green environment
MONITOR_TIMEOUT=30     # Default critical monitoring duration in seconds
CHECK_INTERVAL=5       # Interval between live traffic checks

# Flag Variables
TEST_SUCCESS="true" # Controls simulation outcome (true/false)
SHOW_HELP="false"   # Variable to track if help was requested

# --- Functions ---

# Function to display script usage
function usage() {
    echo "Usage: $0 [-s <true|false>] [-t <seconds>] [-h]"
    echo "Usage: $0 [--success <true|false>] [--time <seconds>] [--help]"
    echo ""
    echo "Options:"
    echo "  -s, --success <true|false>  Controls the simulation of the critical monitoring phase."
    echo "                              'true' (default): Monitoring succeeds (no rollback)."
    echo "                              'false': Monitoring fails, triggering an immediate rollback."
    echo "  -t, --time <seconds>        Sets the length of the critical monitoring duration in seconds (Default: ${MONITOR_TIMEOUT}s)."
    echo "  -h, --help                  Display this help message and exit."
    exit 0 # Exit successfully after showing help
}

# Function to update the HTTPRoute weights via kubectl apply
function switch_traffic() {
    local blue_weight=$1
    local green_weight=$2
    local msg=$3

    echo "-> Applying HTTPRoute configuration: $msg"

    # Use kubectl apply with a dynamically generated YAML document
    # NOTE: The closing 'EOF' *must* be on a line by itself with no preceding whitespace.
    kubectl apply -n ${NAMESPACE} -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: ${APP_NAME}-route
  namespace: ${NAMESPACE}
spec:
  parentRefs:
  - name: webstore-gateway
  hostnames:
  - "${HOST_NAME}"
  rules:
  - backendRefs:
    - name: ${BLUE_SVC}
      port: 80
      weight: ${blue_weight}
    - name: ${GREEN_SVC}
      port: 80
      weight: ${green_weight}
EOF

    if [ $? -ne 0 ]; then
        echo "❌ ERROR: Failed to update HTTPRoute."
        exit 1
    fi
    echo "Traffic weights updated: Blue=${blue_weight}%, Green=${green_weight}%."
}

# Function to simulate critical monitoring
function monitor_live_traffic() {
    echo "-> Starting critical live traffic monitoring for ${MONITOR_TIMEOUT} seconds (TEST_SUCCESS=${TEST_SUCCESS})..."

    local start_time=$(date +%s)
    local end_time=$((start_time + MONITOR_TIMEOUT))
    local current_time=$start_time
    local elapsed=0

    # If the user explicitly set the flag to "false", we trigger a failure immediately.
    if [[ "${TEST_SUCCESS}" == "false" ]]; then
        # Introduce a short delay to simulate initial success before failure
        sleep 5 
        echo ""
        echo "❌ SIMULATING CRITICAL FAILURE based on --success false flag. Rolling back!"
        return 1 # Return non-zero for failure
    fi

    # If the user set the flag to "true" (or used default), we simulate a successful run.
    while [ ${current_time} -lt ${end_time} ]; do
        
        # --- SUCCESS SIMULATION ---
        current_time=$(date +%s)
        elapsed=$((current_time - start_time))
        echo "   (Time elapsed: ${elapsed}s/${MONITOR_TIMEOUT}s) - Metrics look good. Continuing..."

        # In a real deployment, the 'sleep' here would be followed by a real metric query.
        sleep ${CHECK_INTERVAL}
    done

    echo "✅ Critical monitoring period complete. No critical errors detected."
    return 0 # Success
}

# Function to perform instant rollback
function rollback() {
    echo ""
    echo "🚨 CRITICAL FAILURE DETECTED! INITIATING INSTANT ROLLBACK 🚨"
    switch_traffic 100 0 "ROLLBACK: Switching 100% traffic back to Blue (V1)"
    echo "✅ ROLLBACK COMPLETE. The Green environment remains available for debugging."
    exit 1
}

# --- Argument Parsing ---

# Handle short flags (-s, -t, -h)
while getopts ":s:t:h" opt; do
    case "${opt}" in
        s)
            # FIX: Use tr for POSIX-compliant lowercasing
            TEST_SUCCESS=$(echo "${OPTARG}" | tr '[:upper:]' '[:lower:]')
            if [[ "$TEST_SUCCESS" != "true" && "$TEST_SUCCESS" != "false" ]]; then
                echo "❌ Error: -s value must be 'true' or 'false'."
                usage
            fi
            ;;
        t)
            # Check if value is a positive integer
            if ! [[ "${OPTARG}" =~ ^[0-9]+$ ]] || [ "${OPTARG}" -le 0 ]; then
                echo "❌ Error: -t value must be a positive integer in seconds."
                usage
            fi
            MONITOR_TIMEOUT="${OPTARG}"
            ;;
        h)
            SHOW_HELP="true"
            ;;
        :)
            echo "❌ Error: Option -$OPTARG requires an argument."
            usage
            ;;
        *)
            echo "❌ Error: Invalid option -$OPTARG."
            usage
            ;;
    esac
done
shift "$((OPTIND - 1))"

# Handle long flags (--success, --time, --help)
for arg in "$@"; do
    case "$arg" in
        --success=*)
            TEST_SUCCESS="${arg#*=}"
            # FIX: Use tr for POSIX-compliant lowercasing
            TEST_SUCCESS=$(echo "${TEST_SUCCESS}" | tr '[:upper:]' '[:lower:]')
            if [[ "$TEST_SUCCESS" != "true" && "$TEST_SUCCESS" != "false" ]]; then
                echo "❌ Error: --success value must be 'true' or 'false'."
                usage
            fi
            ;;
        --time=*)
            MONITOR_TIMEOUT="${arg#*=}"
            # Check if value is a positive integer
            if ! [[ "${MONITOR_TIMEOUT}" =~ ^[0-9]+$ ]] || [ "${MONITOR_TIMEOUT}" -le 0 ]; then
                echo "❌ Error: --time value must be a positive integer in seconds."
                usage
            fi
            ;;
        --help)
            SHOW_HELP="true"
            ;;
        *)
            # Handle any remaining unrecognized non-flag arguments
            ;;
    esac
done

# --- CORRECTIVE ACTION: Display usage if help was requested OR no arguments were passed ---
if [[ "${SHOW_HELP}" == "true" ]]; then
    usage
fi

# If no flags are provided, we show usage for convenience.
if [ "$#" -eq 0 ] && [ "$OPTIND" -eq 1 ]; then
    usage
fi

echo "Starting Blue-Green Deployment of ${APP_NAME} to V2.0.0 in namespace ${NAMESPACE}."
echo "------------------------------------------------------------------------"
echo "Deployment Settings:"
echo "  Success Simulation: ${TEST_SUCCESS}"
echo "  Monitoring Duration: ${MONITOR_TIMEOUT}s"
echo "------------------------------------------------------------------------"

# --- Deployment Workflow ---

# 1. Deploy the Green environment (V2)
echo "1. Deploying Green environment (${NEW_IMAGE_TAG})..."
# NOTE: Assume green deployment and service YAMLs (webstore-green-deploy.yaml) 
# have been applied here using the ${NEW_IMAGE_TAG}.
kubectl apply -f webstore-green-deploy.yaml
kubectl apply -f webstore-green-svc.yaml

# Wait for Green pods to be ready
echo "-> Waiting for Green pods to be ready..."
kubectl wait --namespace=${NAMESPACE} --for=condition=ready pod -l version=green --timeout=300s
if [ $? -ne 0 ]; then
    echo "❌ ERROR: Green deployment pods failed to become ready. Aborting."
    exit 1
fi
echo "-> Green Deployment is running and ready for traffic."

# 2. Synthetic Pre-Check
echo "2. Performing pre-check tests against the Green Service (not live traffic)..."
sleep 5
echo "-> Synthetic tests passed."

# 3. Instant Traffic Switch
switch_traffic 0 100 "PRODUCTION SWITCH: Switching 100% traffic to Green (V2)"

# 4. Critical Post-Switch Monitoring
if monitor_live_traffic; then
    echo "------------------------------------------------------------------------"
    echo "✅ DEPLOYMENT SUCCESS: Green (V2) is stable after critical monitoring."
    echo "The old Blue environment (V1) can now be decommissioned or prepared for the next release."
    echo "------------------------------------------------------------------------"
else
    # If monitor_live_traffic returned non-zero (1), execute rollback
    rollback
fi

# 5. Final State: Green is Live (100%), Blue is Idle.
