Kubernetes Health Probe Testing Instructions

### How to Build 

# Step 1: Compile the Go Application (Optional but Recommended)
While the Dockerfile handles compilation, running this command locally ensures the code compiles correctly for the target Linux environment:
# Compile for Linux (the target OS inside the container)

cd app
CGO_ENABLED=0 GOOS=linux 
go build -o edu-health-probe main.go

# Step 2: Build the Docker Image
Use the `docker build` command to execute the steps in the `Dockerfile`. You must tag the image to match the format you plan to use in the Canvas.
Using the application name from your selected text in the Canvas (`scale-test`):
# Use 'wmdailey' with your Docker Hub username or registry prefix
# Replace 'latest' with a version tag (e.g., v1.0.0)

cd ..
docker build -t wmdailey/edu-health-probe:latest .

# Step 3: Push the Image to a Registry
For Kubernetes (especially managed services like GKE or EKS) to access the image, it must be pushed to a public or private container registry.

docker push wmdailey/edu-health-probe:latest

### Run the probes

These instructions guide you through running the Go application and testing its Liveness (/livez) and Readiness (/readyz) probes using curl.

Step 1: Test run the Go Server

kubectl apply -f health-probe-deploy.yaml -f 

Step 2: Use either the port forward or the loadbalancer to access from the local host.

kubectl port-forward service/health-probe-svc 8080:8080

The server will start on port 8080 and log its current state.

Step 3: Initial Live and Ready Check
When the server starts, both Liveness and Readiness probes are initially true (healthy). The curl command can be run from a Pod. The http command can be run from a browser.

##Endpoint
Purpose
Command
Expected Status

##State
Check if the application is alive.
curl -i http://health-probe-svc.default.svc.cluster.local:8080/livez
http://live-probe.local:8080/info
HTTP 200 OK

Step 4: Simulate Liveness Failure (Crash/Restart) A liveness failure means the application is in a non-recoverable state and must be restarted.

##Liveness
Check if the application is alive.
curl -i http://health-probe-svc.default.svc.cluster.local:8080/livez
http://live-live-probe.local:8080/livez
HTTP 200 OK

##Toggle Liveness to false (Failing):
curl http://health-probe-svc.default.svc.cluster.local:8080/toggle/liveness
http://live-probe.local:8080/toggle/liveness
# Output: Liveness state successfully toggled to: false

##Verify Liveness Status:
In Kubernetes, a 500 status would trigger the Kubelet to kill and restart the container.
curl -i http://health-probe-svc.default.svc.cluster.local:8080/livez
http://live-probe.local:8080/livez
# Expected Status: HTTP 500 Internal Server Error

##Verify Readiness Status (Also Fails):
curl -i http://health-probe-svc.default.svc.cluster.local:8080/readyz
http://live-probe.local:8080/readyz
# Expected Status: HTTP 503 Service Unavailable (since the app is considered broken)

##Toggle Liveness back to true (Alive):
curl http://health-probe-svc.default.svc.cluster.local:8080/toggle/liveness
http://live-probe.local:8080/toggle/liveness
# Output: Liveness state successfully toggled to: true

##Liveness
Check if the application is alive.
curl -i http://health-probe-svc.default.svc.cluster.local:8080/livez
http://live-probe.local:8080/livez
HTTP 200 OK

Step 5: Simulate Readiness Failure (Service Unavailable) A readiness failure means the pod is still running but should temporarily stop receiving traffic (e.g., database connection lost).

##Liveness
Check if the application is alive.
curl -i http://health-probe-svc.default.svc.cluster.local:8080/livez
http://live-probe.local:8080/livez
HTTP 200 OK

##Readiness
Check if the application is ready to accept traffic.
curl -i http://health-probe-svc.default.svc.cluster.local:8080/readyz
http://ready-probe.local:8080/readyz
HTTP 200 OK

##Toggle Readiness to false (Not Ready):
curl -i http://health-probe-svc.default.svc.cluster.local:8080/toggle/readiness
http://ready-probe.local:8080/toggle/readiness
# Output: Readiness state successfully toggled to: false

##Verify Readiness Status:
In Kubernetes, a 503 status would cause the pod to be removed from the Service's endpoints.
curl -i http://health-probe-svc.default.svc.cluster.local:8080/readyz
http://ready-probe.local:8080/readyz
# Expected Status: HTTP 503 Service Unavailable

##Verify Liveness Status (Remains Healthy):
The pod is still running, just not ready to work.
curl -i http://health-probe-svc.default.svc.cluster.local:8080/livez
http://ready-probe.local:8080/livez
# Expected Status: HTTP 200 OK

##Toggle Readiness back to true (Ready):
curl -i http://health-probe-svc.default.svc.cluster.local:8080/toggle/readiness
http://ready-probe.local:8080/toggle/readiness
# Output: Readiness state successfully toggled to: true

##Readiness
Check if the application is ready to accept traffic.
curl -i http://health-probe-svc.default.svc.cluster.local:8080/readyz
http://ready-probe.local:8080/readyz
HTTP 200 OK

This setup gives you full control over the health states to simulate real-world Kubernetes scenarios!
