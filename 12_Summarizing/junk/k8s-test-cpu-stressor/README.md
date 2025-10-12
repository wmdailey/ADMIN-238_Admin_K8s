#CPU-Stress Tool

The k8s-cpu-stressor is a tool designed to simulate CPU stress on Kubernetes pods. It allows you to specify the desired CPU usage and stress duration, helping you test the behavior of your Kubernetes cluster under different CPU load scenarios.

## Features

* Simulates CPU stress on Kubernetes pods.
* Configurable CPU usage (in millicores) and stress duration.
* Option to run CPU stress indefinitely.
* Adaptive feedback control mechanism to maintain target CPU usage.
* Respects Kubernetes resource limits.
* Helps evaluate Kubernetes cluster performance and resource allocation.

## Getting Started

### Prerequisites

To use the k8s-cpu-stressor, you need to have the following installed:

Go (version 1.24 or higher)
Docker

### Building the Binary

1. (Used for testing the build only) Build the binary using the following command:
	go build -o k8s-cpu-stressor .

### Running with Docker

1. Build the Docker image using the provided Dockerfile:
	docker build -t k8s-cpu-stressor .

2. Run the Docker container, specifying the desired CPU usage, stress duration, and optionally whether to run CPU stress indefinitely:
	#docker run --rm k8s-cpu-stressor -cpu=0.2 -duration=10s -forever 
	#docker run -p 8080:8080 --rm k8s-cpu-stressor -cpu=0.2 -duration=10s -forever 
  docker run -p 30080:8080 k8s-cpu-stressor

3. Replace 0.2 and 10s with the desired CPU usage (fraction) and duration, respectively. Add -forever flag to run CPU stress indefinitely.

4. Retag for Docker Hub
	docker tag k8s-cpu-stressor wmdailey/k8s-cpu-stressor:latest

5. Login to Docker Hub
	docker login

6. Push the image into Docker Hub.
	docker push wmdailey/k8s-cpu-stressor:latest

### CPU Usage and Duration

The k8s-cpu-stressor allows you to specify the desired CPU usage and stress duration using the following parameters:

* CPU Usage: The CPU usage is defined as a fraction of CPU resources. It is specified using the -cpu argument. For example, -cpu=0.2 represents a CPU usage of 20% or 200 milliCPU (mCPU).

* Stress Duration: The stress duration defines how long the CPU stress operation should run. It is specified using the -duration argument, which accepts a duration value with a unit. Supported units include seconds (s), minutes (m), hours (h), and days (d). For example, -duration=10s represents a stress duration of 10 seconds, -duration=5m represents 5 minutes, -duration=2h represents 2 hours, and -duration=1d represents 1 day.

* Run Indefinitely: To run CPU stress indefinitely, include the -forever flag.

Adjust these parameters according to your requirements to simulate different CPU load scenarios.

## Configure for Kubernetes 

### Kubernetes Resource Requests and Limits

It is recommended to specify Kubernetes resource requests and limits to control the amount of CPU resources consumed by the pod, and to prevent stressoring your cluster. For example:

* Requests: This defines the minimum amount of CPU that the pod is guaranteed to have.

* Limits: This defines the maximum amount of CPU that the pod can use.

Adding requests and limits helps Kubernetes manage resources efficiently and ensures that your cluster remains stable during stress testing.

Example:

resources:
  requests:
    cpu: "100m"
  limits:
    cpu: "200m"
Check the Public Docker Image

The k8s-cpu-stressor Docker image is publicly available on Docker Hub. You can check and pull the image using the following command:

* docker pull wmdailey/k8s-cpu-stressor:latest

### Sample Deployment Manifest

Use the following deployment manifest as a starting point to deploy the k8s-cpu-stressor image in your Kubernetes cluster:

apiVersion: apps/v1
kind: Deployment
metadata:
  name: k8s-cpu-stressor-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: k8s-cpu-stressor
  template:
    metadata:
      labels:
        app: k8s-cpu-stressor
    spec:
      containers:
        - name: k8s-cpu-stressor
          image: narmidm/k8s-cpu-stressor:latest
          args:
            - "-cpu=0.2"
            - "-duration=10s"
            - "-forever"
          resources:
            limits:
              cpu: "200m"
            requests:
              cpu: "100m"

### Sample Job Manifest

If you want to run the CPU performance testing pod for a fixed duration as a one-time job, you can use the following Kubernetes Job manifest:

apiVersion: batch/v1
kind: Job
metadata:
  name: k8s-cpu-stressor-job
spec:
  template:
    metadata:
      labels:
        app: k8s-cpu-stressor
    spec:
      containers:
        - name: k8s-cpu-stressor
          image: narmidm/k8s-cpu-stressor:latest
          args:
            - "-cpu=0.5"
            - "-duration=5m"
          resources:
            limits:
              cpu: "500m"
            requests:
              cpu: "250m"
      restartPolicy: Never
  backoffLimit: 3

This manifest runs the k8s-cpu-stressor as a Kubernetes Job, which will execute the stress test once for 5 minutes and then stop. The backoffLimit specifies the number of retries if the job fails.

## How It Works

The CPU performance testing pod uses an adaptive feedback control mechanism to maintain the target CPU usage even in constrained environments:

* Baseline Measurement: At startup, the tool measures the baseline CPU performance of the environment.

* Feedback Control: A continuous monitoring loop measures actual CPU usage and dynamically adjusts the workload to match the target usage.

* Resource Awareness: The tool respects container CPU limits, preventing resource overconsumption.

* Adaptive Scaling: The control mechanism automatically adapts to different CPU allocations, from very small (100m) to large (multiple cores).

This approach ensures consistent behavior across different Kubernetes environments, regardless of the underlying hardware or resource constraints.
