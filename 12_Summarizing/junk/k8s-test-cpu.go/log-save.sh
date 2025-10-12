#!/bin/bash

# Check if both log filename and label are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <log_filename> <label_value>"
    exit 1
fi

# Assign command-line arguments to variables
log_file="$1"
label_value="$2"

# Remove existing log file to start fresh
rm -f "$log_file"

# Function to check if all pods are completed
all_pods_completed() {
    local all_completed="0"  # Initialize flag to indicate completion status
    # Iterate over each line of pod information
    while IFS= read -r line; do
        all_completed="1"  # Assume at least one pod is present
        status=$(echo "$line" | awk '{print $2}')  # Extract the pod's status
        if [ "$status" != "Succeeded" ]; then
            all_completed="2"  # If any pod hasn't succeeded, set flag
            break  # Exit loop early if a pod hasn't succeeded
        fi
    done <<< "$(kubectl get pods -l k6_cr="$label_value" -l runner=true -o custom-columns=NAME:.metadata.name,STATUS:.status.phase --no-headers)"
    echo "$all_completed"  # Output the completion status
    if [ "$all_completed" = "2" ]; then
        return 1  # Not all pods have succeeded
    elif [ "$all_completed" = "0" ]; then
        return 2  # No pods found
    else
        return 0  # All pods have succeeded
    fi
}

# Main loop to monitor pod statuses
while true; do
    # Retrieve pods with specified labels
    pods=$(kubectl get pods -l k6_cr="$label_value" -l runner=true -o custom-columns=NAME:.metadata.name,STATUS:.status.phase --no-headers)

    if [ -z "$pods" ]; then
        echo "No pods found with label k6_cr=$label_value. Exiting."
        break  # Exit loop if no pods are found
    else
        echo "Current pod statuses: $pods"  # Display current pod statuses
        all_pods_completed  # Check if all pods have completed
        completion_status=$?  # Capture the function's return value
        echo "Completion status: $completion_status"
        if [ $completion_status -eq 0 ]; then
            echo "All pods have completed."
            break  # Exit loop if all pods have succeeded
        fi
    fi

    sleep 5  # Wait for 5 seconds before rechecking
done

# Iterate over each pod to fetch and log its output
while IFS= read -r line; do
    pod_name=$(echo "$line" | awk '{print $1}')  # Extract the pod's name
    echo "Fetching logs for pod: $pod_name"
    kubectl logs -f "$pod_name" --tail 100 >> "$log_file"  # Append the last 100 lines of the pod's logs to the specified log file
    echo "" >> "$log_file"  # Add a newline for separation
done <<< "$(kubectl get pods -l k6_cr="$label_value" -l runner=true -o custom-columns=NAME:.metadata.name,STATUS:.status.phase --no-headers)"
