#!/bin/bash
#
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

# Title: ns-netpol-check.sh
# Author: WKD
# Version: 3.2.0
# Date: 17JUN25
# Purpose: 

# DEBUG
#set -x
#set -eu
#set >> /tmp/setvar.txt

# VARIABLE
NUM_ARG=$#
OPTION=$1
NS=db-ns
APP_POD=app01-pod
APP_NS=prd-ns
APP_IP=0.0.0.0
APP_PORT=3000
BAK_POD=bak01-pod
BAK_NS=default
BAK_IP=0.0.0.0
BAK_PORT=80
DB_POD=db01-pod
DB_NS=db-ns
DB_IP=0.0.0.0
DB_PORT=6379
WEB_POD=web01-pod
WEB_NS=prd-ns
WEB_IP=0.0.0.0
WEB_PORT=80
W3B_POD=web01-pod
W3B_NS=dev-ns
W3B_IP=0.0.0.0
W3B_PORT=80

# FUNCTION

function usage() {
        echo "Usage: $(basename $0) [OPTION]"
        exit
}

function get_help() {
# help page

cat << EOF
SYNOPSIS
        traffic_check.sh [OPTION]

DESCRIPTION
        Run a traffic check against Pods

        -h, --help
                Help page
        -c, --check
                Set IP address and check ports.
        -i, --install
		Install netcat packages
        -t, --traffic
                Test traffic between Pods 
	-s, --setup
		Set up application
EOF
	exit
}

function check_arg() {
# Check if arguments exits

        if [ ${NUM_ARG} -ne "$1" ]; then
                usage
        fi
}

function run_app() {
	
	if [ -e $(pwd)/k8s/web01-pod.yaml ]; then
		kubectl apply -f k8s/
	else
		echo "ERROR: file app01-pod.yaml not found."
	fi
}

function extract_pod_ip() {

  	# Get the FRONTEND Pod's IP using kubectl and parse with awk
  	APP_IP=$(kubectl get pod "$APP_POD" -n "$APP_NS" -o wide 2>/dev/null | \
        awk 'NR>1 {print $6}')
  	if [[ -z "$APP_IP" ]]; then
    		echo "  ERROR: Could not find IP Address for FRONTEND Pod '$APP_POD' in namespace '$APP_NS'. Check pod name and namespace." >&2
    		return 1
  	fi

  	# Get the BACKEND Pod's IP using kubectl and parse with awk
  	WEB_IP=$(kubectl get pod "$WEB_POD" -n "$WEB_NS" -o wide 2>/dev/null | \
        awk 'NR>1 {print $6}')
  	if [[ -z "$WEB_IP" ]]; then
    		echo "  ERROR: Could not find IP Address for BACKEND Pod '$WEB_PORT' in namespace '$WEB_NS'. Check pod name and namespace." >&2
    		return 1
	fi

  	# Get the BACKEND Pod's IP using kubectl and parse with awk
  	W3B_IP=$(kubectl get pod "$W3B_POD" -n "$W3B_NS" -o wide 2>/dev/null | \
        awk 'NR>1 {print $6}')
  	if [[ -z "$W3B_IP" ]]; then
    		echo "  ERROR: Could not find IP Address for BACKEND Pod '$W3B_PORT' in namespace '$W3B_NS'. Check pod name and namespace." >&2
    		return 1
	fi

  	# Get the DATABASE Pod's IP using kubectl and parse with awk
  	DB_IP=$(kubectl get pod "$DB_POD" -n "$DB_NS" -o wide 2>/dev/null | \
        awk 'NR>1 {print $6}')
  	if [[ -z "$DB_IP" ]]; then
    		echo "  ERROR: Could not find IP Address for DATABASE Pod '$DB_POD' in namespace '$DB_NS'. Check pod name and namespace." >&2
    		return 1
  	fi

  	# Get the BACKUP Pod's IP using kubectl and parse with awk
  	BAK_IP=$(kubectl get pod "$BAK_POD" -n "$BAK_NS" -o wide 2>/dev/null | \
        awk 'NR>1 {print $6}')
  	if [[ -z "$BAK_IP" ]]; then
    		echo "  ERROR: Could not find IP Address for BACKUP Pod '$BAK_POD' in namespace '$BAK_NS'. Check pod name and namespace." >&2
    		return 1
  	fi
}

function show_ip() {

	echo "Check IP address..."
  	echo "  FRONTEND $APP_POD in $APP_NS has IP address: $APP_IP"
  	echo "  BACKEND  $WEB_POD in $WEB_NS has IP address: $WEB_IP"
  	echo "  BACKEND  $W3B_POD in $W3B_NS has IP address: $W3B_IP"
  	echo "  DATABASE $DB_POD in $DB_NS has IP address:   $DB_IP"
  	echo "  BACKUP  $BAK_POD in $BAK_NS has IP address: $BAK_IP"
}
function port_check() {
	local timeout=1

  echo "Check ports..."

	if kubectl -n $APP_NS exec -it $APP_POD -- nc -w $timeout $WEB_IP $WEB_PORT; then
		echo "  FRONTEND $APP_POD in $APP_NS to BACKEND $WEB_POD in $WEB_NS:   OPEN"
	else
		echo "  ERROR: FRONTEND $APP_POD in $APP_NS to BACKEND $WEB_POD: CLOSED or timed out"
		return 1
       fi

	if kubectl -n $APP_NS exec -it $APP_POD -- nc -w $timeout $W3B_IP $W3B_PORT; then
		echo "  FRONTEND $APP_POD in $APP_NS to DEV BACKEND $W3B_POD in $W3B_NS: OPEN"
	else
		echo "  ERROR: FRONTEND $APP_POD in $APP_NS to DEV BACKEND $W3B_POD: CLOSED or timed out"
		return 1
       fi


	if kubectl -n $WEB_NS exec -it $WEB_POD -- nc -w $timeout $DB_IP $DB_PORT; then
		echo "  PRD BACKEND $WEB_POD in $WEB_NS to DATABASE $DB_POD in $DB_NS: OPEN"
	else
		echo "  ERROR: PRD BACKEND $WEB_POD in $WEB_NS to DATABASE $DB_POD: CLOSED or timed out"
		return 1
        fi

	if kubectl -n $W3B_NS exec -it $W3B_POD -- nc -w $timeout $DB_IP $DB_PORT; then
		echo "  DEV BACKEND $W3B_POD in $W3B_NS to DATABASE $DB_POD in $DB_NS: OPEN"
	else
		echo "  ERROR: DEV BACKEND $W3B_POD in $W3B_NS to DATABASE $DB_POD: CLOSED or timed out"
		return 1
        fi

	if kubectl -n $DB_NS exec -it $DB_POD -- nc -w $timeout $WEB_IP $WEB_PORT; then
 		echo "  DATABASE $DB_POD in $DB_NS to BACKEND $WEB_POD in $WEB_NS:     OPEN"
 	else
 		echo "  ERROR: DATABASE $DB_POD in $DB_NS to BACKEND $WEB_POD: CLOSED or timed out"
 		return 1
       fi

	if kubectl -n $DB_NS exec -it $DB_POD -- nc -w $timeout $BAK_IP $BAK_PORT; then
		echo "  DATABASE $DB_POD in $DB_NS to BACKUP $BAK_POD in $BAK_NS:     OPEN"
	else
		echo "  ERROR: DATABASE $DB_POD in $DB_NS to BACKUP $BAK_POD: CLOSED or timed out"
		return 1
        fi
}

function install_package() {
  echo "Installing packages..."

  for pod in $APP_POD; do
  	if kubectl -n $APP_NS exec -it $pod -- sh -c "apt update > /dev/null 2>&1; apt install -y netcat-openbsd > /dev/null 2>&1"; then
		echo "  Install complete on $pod"
	else
		echo "  ERROR: Install failed on $pod"
		return 1
	fi
  done
  echo "Packages installed"
}

function check_command_status() {
   "$@"
   local exit_code=$?

   if [ ${exit_code} -eq 0 ]; then
      echo "Command '$*' successful."
   else
      echo "ERROR: Command '$*' failed."
   fi
}

function traffic_check() {
  echo "Check connectivity..."
}

function traffic_check_from_app() {
  echo
  echo "* FRONTEND $APP_POD in $APP_NS to BACKEND $WEB_POD in $WEB_NS:"
  check_command_status kubectl -n $APP_NS exec $APP_POD -- sh -c "nc -w 1 $WEB_IP $WEB_PORT"
  echo
  echo "* FRONTEND $APP_POD in $APP_NS to DATABASE $DB_POD in $DB_NS:"
  check_command_status kubectl -n $APP_NS exec $APP_POD -- sh -c "nc -w 1 $DB_IP $DB_PORT"

  echo
  echo "* FRONTEND $APP_POD in $APP_NS to DEV BACKEND $W3B_POD in $W3B_NS:"
  check_command_status kubectl -n $APP_NS exec $APP_POD -- sh -c "nc -w 1 $W3B_IP $W3B_PORT"
}

function traffic_check_from_web() {
  echo
  echo "* BACKEND $WEB_POD in $WEB_NS to FRONTEND $APP_POD in $APP_NS:"
  check_command_status kubectl -n $WEB_NS exec $WEB_POD -- sh -c "nc -w 1 $APP_IP $APP_PORT"
  echo
  echo "* BACKEND $WEB_POD in $WEB_NS to DATABASE $DB_POD in $DB_NS:"
  check_command_status kubectl -n $WEB_NS exec $WEB_POD -- sh -c "nc -w 1 $DB_IP $DB_PORT"
}

function traffic_check_from_w3b() {
  echo
  echo "* DEV BACKEND $W3B_POD in $W3B_POD to FRONTEND $APP_POD in $APP_POD:"
  check_command_status kubectl -n $W3B_NS exec $W3B_POD -- sh -c "nc -w 1 $APP_IP $APP_PORT"
  echo
  echo "* DEV BACKEND $W3B_POD in $W3B_NS to DATABASE $DB_POD in $DB_NS:"
  check_command_status kubectl -n $W3B_NS exec $W3B_POD -- sh -c "nc -w 1 $DB_IP $DB_PORT"
}

function traffic_check_from_db() {
  echo
  echo "* DATABASE $DB_POD in $DB_NS to FRONTEND $APP_POD in $APP_NS:"
  check_command_status kubectl -n $DB_NS exec $DB_POD -- sh -c "nc -w 1 $APP_IP $APP_PORT"
  echo
  echo "* DATABASE $DB_POD in $DB_NS to BACKEND $WEB_POD in $WEB_NS:"
  check_command_status kubectl -n $DB_NS exec $DB_POD -- sh -c "nc -w 1 $WEB_IP $WEB_PORT"
  echo
  echo "* DATABASE $DB_POD in $DB_NS to BACKUP $BAK_POD in $BAK_NS:"
  check_command_status kubectl -n $DB_NS exec $DB_POD -- sh -c "nc -w 1 $BAK_IP $BAK_PORT"
}

function run_option() {
# Case statement for add, delete or list working
# directories for user

        case "${OPTION}" in
                -h | --help)
                        get_help
                        ;;
                -c | --check)
			extract_pod_ip
			show_ip
			echo
                        port_check
                        ;;
		-i | --install)
#			install_package
			echo "This option requires configuration"
			;;
                -t | --traffic)
			extract_pod_ip
			traffic_check
                        traffic_check_from_app
                        traffic_check_from_web
                        traffic_check_from_w3b
                        traffic_check_from_db
                        ;;
		-s | --setup)
			run_app
			;;
                *)
                        usage
                        ;;
        esac
}

function main() {
	run_option
}

# Main
main "$@"
exit 0
