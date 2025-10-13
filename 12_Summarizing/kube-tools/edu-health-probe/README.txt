Kubernetes Health Probe Testing Instructions
These instructions guide you through running the Go application and testing its Liveness (/healthz) and Readiness (/readyz) probes using curl.

Step 1: Run the Go Server
Assuming you saved the code above as health_server.go, run it from your terminal:

go run health_server.go

The server will start on port 8080 and log its current state.

Step 2: Initial Healthy and Ready Check
When the server starts, both Liveness and Readiness probes are initially true (healthy).

##Endpoint
Purpose
Command
Expected Status

##Readiness
Check if the application is ready to accept traffic.
curl -i http://localhost:8080/readyz
HTTP 200 OK

##Liveness
Check if the application is alive.
curl -i http://localhost:8080/healthz
HTTP 200 OK

Step 3: Simulate Readiness Failure (Service Unavailable) A readiness failure means the pod is still running but should temporarily stop receiving traffic (e.g., database connection lost).

##Toggle Readiness to false (Not Ready):
curl http://localhost:8080/toggle/readiness
# Output: Readiness state successfully toggled to: false

##Verify Readiness Status:
In Kubernetes, a 503 status would cause the pod to be removed from the Service's endpoints.
curl -i http://localhost:8080/readyz
# Expected Status: HTTP 503 Service Unavailable

##Verify Liveness Status (Remains Healthy):
The pod is still running, just not ready to work.
curl -i http://localhost:8080/healthz
# Expected Status: HTTP 200 OK

##Toggle Readiness back to true (Ready):
curl http://localhost:8080/toggle/readiness
# Output: Readiness state successfully toggled to: true

Step 4: Simulate Liveness Failure (Crash/Restart) A liveness failure means the application is in a non-recoverable state and must be restarted.

##Toggle Liveness to false (Failing):
curl http://localhost:8080/toggle/liveness
# Output: Liveness state successfully toggled to: false

##Verify Liveness Status:
In Kubernetes, a 500 status would trigger the Kubelet to kill and restart the container.
curl -i http://localhost:8080/healthz
# Expected Status: HTTP 500 Internal Server Error

##Verify Readiness Status (Also Fails):
curl -i http://localhost:8080/readyz
# Expected Status: HTTP 503 Service Unavailable (since the app is considered broken)

##Toggle Liveness back to true (Alive):
curl http://localhost:8080/toggle/liveness
# Output: Liveness state successfully toggled to: true

This setup gives you full control over the health states to simulate real-world Kubernetes scenarios!
