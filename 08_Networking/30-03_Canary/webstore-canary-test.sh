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

# Title: canary-test.sh
# Author: WKD
# Version: 3.3.0
# Date: 23OCT25 (Updated for flag parsing)
# Description:
# canary-test.sh - Uses the X-Version header injected by Envoy Gateway to verify the 90/10 split.
# Requires: jq (JSON processor) and curl.
# Usage: ./canary-test.sh -g <GATEWAY_IP> [-c <REQUEST_COUNT>] [-h <HOST_HEADER>]

# --- Default Variables ---
# Default request count and hostname
REQUEST_COUNT=20
HOST_HEADER="canary.local"
GATEWAY_IP="" # Must be set via flag

# --- Function Definitions ---

# Function to display script usage
usage() {
    echo "Usage: $0 -g <GATEWAY_IP> [-c <REQUEST_COUNT>] [-h <HOST_HEADER>]"
    echo ""
    echo "Options:"
    echo "  -g <IP>             Gateway IP address (REQUIRED)."
    echo "  -h <HOSTNAME>       Value for the 'Host' header (Default: ${HOST_HEADER})."
    echo "  -c <COUNT>          Number of requests to send (Default: ${REQUEST_COUNT})."
    exit 1
}

# --- 1. Parse Input Flags ---

# 'g:', 'c:', and 'h:' indicate that these options require an argument.
while getopts "g:c:h:" opt; do
    case "${opt}" in
        g)
            GATEWAY_IP="${OPTARG}"
            ;;
        c)
            REQUEST_COUNT="${OPTARG}"
            # Basic validation for request count
            if ! [[ "$REQUEST_COUNT" =~ ^[0-9]+$ ]] || [ "$REQUEST_COUNT" -le 0 ]; then
                echo "❌ Error: Request count (-c) must be a positive integer."
                usage
            fi
            ;;
        h)
            HOST_HEADER="${OPTARG}"
            ;;
        *)
            usage
            ;;
    esac
done

# --- 2. Validate Required Input ---

if [ -z "$GATEWAY_IP" ]; then
    echo "❌ Error: Missing GATEWAY_IP. Use the -g flag."
    usage
fi

echo "--- Starting Envoy Gateway Canary Test (Final Header Injection) ---"
echo "Target IP: ${GATEWAY_IP}"
echo "Host Header: ${HOST_HEADER}"
echo "Request Count: ${REQUEST_COUNT}"
echo "Expected Split: 90% Stable / 10% Canary (approx.)"
echo "-----------------------------------------------------------------"

# --- 3. Initialize Simple Counters ---

STABLE_COUNT=0
CANARY_COUNT=0
UNKNOWN_COUNT=0

# --- 4. Run Test Loop ---

for ((i = 1; i <= REQUEST_COUNT; i++)); do
    # Curl command sends request with the required Host header (using $HOST_HEADER).
    # jq extracts the X-Version header value, which is injected by Envoy based on the weight.
    # The Host header is dynamically set using the -h flag value.
    RESPONSE=$(curl -s -H "Host: ${HOST_HEADER}" "http://${GATEWAY_IP}/headers" | jq -r '.headers["X-Version"]')

    case "$RESPONSE" in
        "stable")
            STABLE_COUNT=$((STABLE_COUNT + 1))
            ;;
        "canary")
            CANARY_COUNT=$((CANARY_COUNT + 1))
            ;;
        *)
            # Counts cases where jq returns 'null' or the connection fails.
            UNKNOWN_COUNT=$((UNKNOWN_COUNT + 1))
            ;;
    esac
done

# --- 5. Display Results ---

echo ""
echo "Test Results (Total Requests: ${REQUEST_COUNT}):"
echo "-----------------------------------"

# Calculate percentages (will round down due to integer arithmetic)
# Using 'scale=2' with 'bc' for more accurate percentage calculation.
stable_percent=$(echo "scale=2; 100 * ${STABLE_COUNT} / ${REQUEST_COUNT}" | bc)
canary_percent=$(echo "scale=2; 100 * ${CANARY_COUNT} / ${REQUEST_COUNT}" | bc)

echo "✅ Stable (90% Weight): ${STABLE_COUNT} requests (${stable_percent}%)"
echo "🔀 Canary (10% Weight): ${CANARY_COUNT} requests (${canary_percent}%)"

if [ ${UNKNOWN_COUNT} -gt 0 ]; then
    echo "⚠️ Unknown/Error: ${UNKNOWN_COUNT} requests"
fi

echo "-----------------------------------"
