#Memory Performance Testing Tool

The test-memory is a tool designed to simulate CPU stress on Kubernetes pods. It allows you to specify the desired CPU usage and stress duration, helping you test the behavior of your Kubernetes cluster under different CPU load scenarios.

## Getting Started

### Prerequisites

To use the test-memory, you need to have the following installed:

Go (version 1.24 or higher)
Docker

### Building the Binary

1. (Used for testing the build only) Build the binary using the following command:
	cd app
	go build -o k8s-test-memory .
	rm k8s-test-memory

### Running with Docker

1. Build the Docker image using the provided Dockerfile:
	cd ..
	docker build -t k8s-test-memory .

2. Run the Docker container, specifying the desired CPU usage, stress duration, and optionally whether to run CPU stress indefinitely:
       docker run -p 8080:8080 k8s-test-memory

  	URL: http://localhost:8080
  	URL: http://localhost:8080/test-memory
	Ctrl-C

3. Retag for Docker Hub
	docker tag k8s-test-memory wmdailey/k8s-test-memory:latest

4. Login to Docker Hub
	docker login

5. Push the image into Docker Hub.
	docker push wmdailey/k8s-test-memory:latest

## Google
 # Use a simple image that simulates CPU usage.
        # This example uses a Python web server that has a resource-intensive endpoint.
        # This image must be accessible from your cluster.
        image: "gcr.io/google-samples/community/k8s-platform-helper-app:0.3"

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

The test-memory Docker image is publicly available on Docker Hub. You can check and pull the image using the following command:

* docker pull wmdailey/test-memory:latest

### Sample Deployment Manifest

Use the following deployment manifest as a starting point to deploy the test-memory image in your Kubernetes cluster:

apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-memory-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: test-memory
  template:
    metadata:
      labels:
        app: test-memory
    spec:
      containers:
        - name: test-memory
          image: wmdailey/test-memory:latest
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
  name: test-memory-job
spec:
  template:
    metadata:
      labels:
        app: test-memory
    spec:
      containers:
        - name: test-memory
          image: wmdailey/test-memory:latest
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


INSTALLING THE AUTOSCALER
Installation Steps:
Clone the VPA Repository: Obtain the VPA source code by cloning the official Kubernetes autoscaler repository:
Code

    git clone https://github.com/kubernetes/autoscaler.git
Navigate to the VPA Directory: Change your current directory to the vertical-pod-autoscaler subdirectory within the cloned repository:
Code

    cd autoscaler/vertical-pod-autoscaler
Deploy the VPA Components: Execute the installation script provided in the repository. This script deploys the necessary VPA components, including the Admission Controller, Recommender, and Updater: 
Code

    ./hack/vpa-up.sh
Verify VPA Deployment: Confirm that the VPA components are installed and running by checking the pods in the kube-system namespace:
Code

    kubectl get pods -n kube-system | grep vpa
You should see pods related to the Vertical Pod Autoscaler running. 

vpa-admission-controller-745674c585-j764k   1/1     Running   0          5s
vpa-recommender-58c97dd8d7-s5h1j            1/1     Running   0          5s
vpa-updater-6c84b4944d-j9t2r               1/1     Running   0          5s

Using VPA:
Once VPA is installed, you can create VerticalPodAutoscaler objects for the deployments you want to autoscale. This involves defining a VPA object in YAML, specifying the target deployment and the desired updateMode (e.g., Auto). The VPA will then automatically adjust the resource requests of your pods based on their historical and current resource usage. 

Download the Manifest Files

X. Apply the Manifests
Use kubectl apply with the manifest files to install the VPA components.

kubectl apply -f https://raw.githubusercontent.com/kubernetes/autoscaler/master/vertical-pod-autoscaler/deploy/vpa-up.yaml

This single command applies all the necessary resources, including the Custom Resource Definitions (CRDs), the VPA Recommender, the VPA Updater, and the VPA Admission Controller.

