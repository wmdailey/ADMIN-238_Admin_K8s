#CPU Performance Test Tool

The test-cpu is a tool designed to simulate CPU stress on Kubernetes pods. It allows you to specify the desired CPU usage and stress duration, helping you test the behavior of your Kubernetes cluster under different CPU load scenarios.

## Features

* Simulates CPU stress on Kubernetes pods.
* Configurable CPU usage (in millicores) and stress duration.
* Option to run CPU stress indefinitely.
* Respects Kubernetes resource limits.
* Helps evaluate Kubernetes cluster performance and resource allocation.

## Getting Started

### Prerequisites

To use the test-cpu, you need to have the following installed:

Go (version 1.25 or higher)
Docker

### Building the Binary

1. (Used for testing the build only) Build the binary using the following command:
	cd app
	go build -o k8s-test-cpu .

### Running with Docker

1. Build the Docker image using the provided Dockerfile:
	cd ..
	docker build -t k8s-test-cpu .

2. Run the Docker container, specifying the desired CPU usage, stress duration, and optionally whether to run CPU stress indefinitely:
       docker run -p 8080:8080 k8s-test-cpu

  	URL: http://localhost:8080
  	URL: http://localhost:8080/test-cpu
  	URL: http://localhost:8080/healthz
	Ctrl-C

3. Retag for Docker Hub
	docker tag k8s-test-cpu wmdailey/k8s-test-cpu:latest

4. Login to Docker Hub
	docker login

5. Push the image into Docker Hub.
	docker push wmdailey/k8s-test-cpu:latest

## Configure for Kubernetes 

### Kubernetes Resource Requests and Limits

It is recommended to specify Kubernetes resource requests and limits to control the amount of CPU resources consumed by the pod, and to prevent overloading your cluster. For example:

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

The test-cpu Docker image is publicly available on Docker Hub. You can check and pull the image using the following command:

* docker pull wmdailey/test-cpu:latest

### Sample Deployment Manifest

Use the following deployment manifest as a starting point to deploy the test-cpu image in your Kubernetes cluster:

apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-cpu-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: test-cpu
  template:
    metadata:
      labels:
        app: test-cpu
    spec:
      containers:
        - name: test-cpu
          image: wmdailey/test-cpu:latest
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
  name: test-cpu-job
spec:
  template:
    metadata:
      labels:
        app: test-cpu
    spec:
      containers:
        - name: test-cpu
          image: wmdailey/k8s-test-cpu:latest
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

This manifest runs the test-cpu as a Kubernetes Job, which will execute the stress test once for 5 minutes and then stop. The backoffLimit specifies the number of retries if the job fails.

