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

# Title: monitor-probe.sh
# Author: WKD
# Version: 3.2.0
# Date: 17JUN25

# DEBUG
#set -x
#set -eu
#set >> /tmp/setvar.txt

# VARIABLE

# Configuration Defaults
DEFAULT_POD_LABEL="pod=ready-probe-pod" 
DEFAULT_HAS_READINESS_PROBE="true"
APP_PORT="8080"
READY_PATH="/readyz"
KUBE_CHECK_CMD="kubectl get pod"
SLEEP_INTERVAL=5

# Variables to be set by CLI flags
POD_LABEL=""
HAS_READINESS_PROBE=""
CONTAINER_NAME=""

# Set default values
POD_LABEL="$DEFAULT_POD_LABEL"
HAS_READINESS_PROBE="$DEFAULT_HAS_READINESS_PROBE"

# --- Argument Parsing using getopts/case ---
# Resetting OPTIND is necessary if the script is sourced
OPTIND=1
while getopts ":l:p:" opt; do
    case "$opt" in
        l)  # --label
            POD_LABEL="$OPTARG"
            ;;
        p)  # --probe
            INPUT_PROBE=$(echo "$OPTARG" | tr '[:upper:]' '[:lower:]')
            if [ "$INPUT_PROBE" = "true" ] || [ "$INPUT_PROBE" = "false" ]; then
                HAS_READINESS_PROBE="$INPUT_PROBE"
            else
                echo "❌ Invalid value for --probe. Use 'true' or 'false'. Using default: $DEFAULT_HAS_READINESS_PROBE" >&2
            fi
            ;;
        \?)
            echo "❌ Invalid option: -$OPTARG" >&2
            exit 1
            ;;
        :)
            echo "❌ Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
    esac
done
shift $((OPTIND-1))
# ---------------------------------------------

# --- Set Container Name and Final Log ---
# We derive CONTAINER_NAME based on the label, assuming standard naming convention
if [[ "$POD_LABEL" == *"ready-probe-pod"* ]]; then
    CONTAINER_NAME="ready-probe-app"
elif [[ "$POD_LABEL" == *"no-probe-pod"* ]]; then
    CONTAINER_NAME="no-probe-app"
else
    # Fallback if label is unusual; may cause K8s status to show 'unknown'
    CONTAINER_NAME="unknown-app"
fi

echo "--- Starting Continuous TRUE Application Readiness Monitor ---"
echo "  ✅ Target Label: $POD_LABEL"
echo "  ✅ Scenario: $( [ "$HAS_READINESS_PROBE" = "true" ] && echo "WITH PROBE (Traffic Removal Enabled)" || echo "NO PROBE (Traffic Removal Disabled)" )"
echo "  ✅ Container Name: $CONTAINER_NAME"
echo "Monitoring Pods every ${SLEEP_INTERVAL} seconds. Press Ctrl+C to stop."
echo "------------------------------------------------------------"

while true; do
    TIMESTAMP=$(date +"%T")
    echo "[$TIMESTAMP] Running Readiness Check (Target Label: $POD_LABEL):"

    generate_random_port() {
        echo $(( (RANDOM % 55001) + 10000 ))
    }

    PODS=$($KUBE_CHECK_CMD -l $POD_LABEL -o custom-columns=NAME:.metadata.name --no-headers 2>/dev/null)

    if [ -z "$PODS" ]; then
        echo "   ✅ No Pods found with label '$POD_LABEL'. Waiting for deployment..."
        sleep $SLEEP_INTERVAL
        echo "------------------------------------------------------------"
        continue
    fi

    for POD_NAME in $PODS; do
        # Retrieve the K8s Ready status (for logging/comparison)
        KUBE_STATUS=$($KUBE_CHECK_CMD "$POD_NAME" -o jsonpath="{.status.containerStatuses[?(@.name==\"$CONTAINER_NAME\")].ready}" 2>/dev/null)
        KUBE_STATUS=${KUBE_STATUS:-unknown}

        PHASE=$($KUBE_CHECK_CMD "$POD_NAME" -o jsonpath='{.status.phase}' 2>/dev/null)

        if [ "$PHASE" != "Running" ]; then
            echo "   🟡 $POD_NAME: PHASE: $PHASE. STATUS: NOT ACCEPTING TRAFFIC"
            continue
        fi

        # 1. Start port-forwarding
        LOCAL_PORT=$(generate_random_port)
        kubectl port-forward "$POD_NAME" "$LOCAL_PORT":"$APP_PORT" > /dev/null 2>&1 &
        PF_PID=$!
        
        sleep 2 

        # 2. Check the application's /readyz endpoint
        HTTP_CODE=$(curl -s --connect-timeout 2 -o /dev/null -w '%{http_code}' "http://127.0.0.1:$LOCAL_PORT$READY_PATH" 2>/dev/null)

        # 3. Stop port-forwarding
        kill "$PF_PID" > /dev/null 2>&1
        wait $PF_PID 2>/dev/null

        # 4. Report the status for this individual Pod
        if [ "$HTTP_CODE" -eq 200 ]; then
            # Application is internally ready.
            echo "   🟢 $POD_NAME: TRUE READY (K8s: $KUBE_STATUS). STATUS: ACCEPTING TRAFFIC"
        else
            # Application is NOT internally ready (HTTP 503 or 000)
            
            # --- LOGIC SWITCH BASED ON HAS_READINESS_PROBE VARIABLE ---
            if [ "$HAS_READINESS_PROBE" = "true" ]; then
                # SCENARIO: Probe is present. 503 means K8s removes traffic.
                TRAFFIC_STATUS="NOT ACCEPTING TRAFFIC (Readiness Probe)"
            else
                # SCENARIO: No Probe. Pod is running, so K8s is still routing traffic (Flaw).
                TRAFFIC_STATUS="STILL ACCEPTING TRAFFIC (K8s Flaw)"
            fi
            
            echo "   🔴 $POD_NAME: NOT READY (HTTP $HTTP_CODE). STATUS: $TRAFFIC_STATUS"
        fi
    done
    
    echo "------------------------------------------------------------"

    sleep $SLEEP_INTERVAL
done
