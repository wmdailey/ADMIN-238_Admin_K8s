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

# Title: monitor-probe.sh
# Author: WKD
# Description: Monitors the liveness status of all Kubernetes pods matching a label.
# This script is a passive monitor and does not inject failures.

# --- Configuration ---
APP_PORT="8080"
LIVE_PATH="/livez"
KUBE_CHECK_CMD="kubectl get pod"
SLEEP_INTERVAL=5

# --- Default Values (Assumed based on script logic) ---
DEFAULT_POD_LABEL="app=live-probe-pod" # Example label, adjust if necessary
DEFAULT_HAS_LIVENESS_PROBE="true"    # Scenario flag

# --- Variables ---
POD_LABEL="${DEFAULT_POD_LABEL}"
HAS_LIVENESS_PROBE="${DEFAULT_HAS_LIVENESS_PROBE}"

# --- Helper Functions ---

# Displays the usage information for the script.
show_usage() {
    echo "Usage: $0 [-h] [-l <pod-label>] [-p <true|false>]"
    echo ""
    echo "Monitors the LIVENESS status of Kubernetes pods matching the specified label."
    echo "This script passively reports the status and expected K8s action."
    echo ""
    echo "Options:"
    echo "  -h             Show this help message and exit."
    echo "  -l <label>     The Kubernetes label selector for the pods (e.g., app=my-app)."
    echo "                 (Default: $DEFAULT_POD_LABEL)"
    echo "  -p <status>    Set the scenario: 'true' if the deployment HAS a liveness probe,"
    echo "                 'false' if it does NOT (affects reporting of expected K8s action)."
    echo "                 (Default: $DEFAULT_HAS_LIVENESS_PROBE)"
    echo ""
}

# Helper function to generate a random local port for port-forwarding
generate_random_port() {
    # Generates a port between 10000 and 65000
    echo $(( (RANDOM % 55001) + 10000 ))
}


# --- Argument Parsing using getopts/case ---
OPTIND=1
while getopts ":l:p:h" opt; do
    case "$opt" in
        l)  # -l (label)
            POD_LABEL="$OPTARG"
            ;;
        p)  # -p (probe status: true/false)
            INPUT_PROBE=$(echo "$OPTARG" | tr '[:upper:]' '[:lower:]')
            if [ "$INPUT_PROBE" = "true" ] || [ "$INPUT_PROBE" = "false" ]; then
                HAS_LIVENESS_PROBE="$INPUT_PROBE"
            else
                echo "❌ Invalid value for -p. Use 'true' or 'false'. Using default: $DEFAULT_HAS_LIVENESS_PROBE" >&2
                exit 1
            fi
            ;;
        h)  # -h (Show usage)
            show_usage
            exit 0
            ;;
        \?)
            echo "❌ Invalid option: -$OPTARG" >&2
            show_usage # Show usage on invalid option
            exit 1
            ;;
        :)
            echo "❌ Option -$OPTARG requires an argument." >&2
            show_usage # Show usage on missing argument
            exit 1
            ;;
    esac
done
shift $((OPTIND-1))
# ---------------------------------------------

# --- Main Logic ---

# --- Continuous Monitoring Loop (Always runs) ---

echo "--- Starting Continuous LIVENESS Probe Status Monitor ---"
echo "  ✅ Target Label: $POD_LABEL"
echo "  ✅ Scenario: $( [ "$HAS_LIVENESS_PROBE" = "true" ] && echo "WITH PROBE (K8s Restarting Enabled)" || echo "NO PROBE (K8s Restarting Disabled)" )"
echo "Monitoring Pods every ${SLEEP_INTERVAL} seconds. Press Ctrl+C to stop."
echo "------------------------------------------------------------"

while true; do
    TIMESTAMP=$(date +"%T")
    echo "[$TIMESTAMP] Running Liveness Check (Target: $LIVE_PATH):"

    PODS=$($KUBE_CHECK_CMD -l "$POD_LABEL" -o custom-columns=NAME:.metadata.name --no-headers 2>/dev/null)

    if [ -z "$PODS" ]; then
        echo "    ✅ No Pods found with label '$POD_LABEL'. Waiting for deployment..."
        sleep "$SLEEP_INTERVAL"
        echo "------------------------------------------------------------"
        continue
    fi

    for POD_NAME in $PODS; do
        # --- Logic to Check Container Status ---
        
        # Dynamically find the container name for the Pod being checked
        CONTAINER_NAME=$(kubectl get pod "$POD_NAME" -o jsonpath='{.spec.containers[0].name}' 2>/dev/null)
        if [ -z "$CONTAINER_NAME" ]; then
            echo "    🔴 ERROR: Could not find container name for Pod $POD_NAME. Skipping."
            continue
        fi
        
        # Retrieve the K8s Ready status
        KUBE_STATUS=$($KUBE_CHECK_CMD "$POD_NAME" -o jsonpath="{.status.containerStatuses[?(@.name==\"$CONTAINER_NAME\")].ready}" 2>/dev/null)
        KUBE_STATUS=${KUBE_STATUS:-unknown}

        PHASE=$($KUBE_CHECK_CMD "$POD_NAME" -o jsonpath='{.status.phase}' 2>/dev/null)

        if [ "$PHASE" != "Running" ]; then
            echo "    🟡 $POD_NAME: PHASE: $PHASE (K8s Ready: $KUBE_STATUS)"
            continue
        fi

        # 1. Start port-forwarding
        LOCAL_PORT=$(generate_random_port)
        kubectl port-forward "$POD_NAME" "$LOCAL_PORT":"$APP_PORT" > /dev/null 2>&1 &
        PF_PID=$!
        sleep 1 # Wait for port-forward connection to establish

        # 2. Check the application's /livez endpoint
        HTTP_CODE=$(curl -s --connect-timeout 2 -o /dev/null -w '%{http_code}' "http://127.0.0.1:$LOCAL_PORT$LIVE_PATH" 2>/dev/null)

        # 3. Stop port-forwarding
        kill "$PF_PID" > /dev/null 2>&1
        wait $PF_PID 2>/dev/null

        # 4. Report the status
        if [ "$HTTP_CODE" -eq 200 ]; then
            echo "    🟢 $POD_NAME: Liveness: HEALTHY (K8s Ready: $KUBE_STATUS)"
        else
            # Application is internally unhealthy (HTTP 500 or 000)
            
            if [ "$HAS_LIVENESS_PROBE" = "true" ]; then
                # SCENARIO: Probe is present. K8s will restart the container on 500.
                ACTION="K8s WILL RESTART CONTAINER"
            else
                # SCENARIO: No Probe. Pod stays broken but K8s takes no action.
                ACTION="K8s TAKES NO ACTION (Broken App Stays Running)"
            fi
            
            echo "    🔴 $POD_NAME: Liveness: FAILED (HTTP $HTTP_CODE). ACTION: $ACTION"
        fi
    done
    
    echo "------------------------------------------------------------"

    sleep "$SLEEP_INTERVAL"
done
