This solution provides a complete load generation tool.

Step 1: Compile the Go Application (Optional but Recommended)
While the Dockerfile handles compilation, running this command locally ensures the code compiles correctly for the target Linux environment:
# Compile for Linux (the target OS inside the container)

CGO_ENABLED=0 GOOS=linux 
go build -o hpa-load-tester main.go

### Step 2: Build the Docker Image
Use the `docker build` command to execute the steps in the `Dockerfile`. You must tag the image to match the format you plan to use in the Canvas.
Using the application name from your selected text in the Canvas (`hpa-load-tester`):
# Use 'wmdailey' with your Docker Hub username or registry prefix
# Replace 'latest' with a version tag (e.g., v1.0.0)

docker build -t wmdailey/hpa-load-tester:latest .

### Step 3: Push the Image to a Registry
For Kubernetes (especially managed services like GKE or EKS) to access the image, it must be pushed to a public or private container registry.

docker push wmdailey/hpa-load-tester:latest

### Step 4: Update the Canvas
Finally, update the Deployment section in your Canvas file (`hpa-test-deployment.yaml`) with the full image path you just pushed (from Step 2).
The line you selected:
```yaml
image: <YOUR-IMAGE-PATH> # Replace with your built Go application image

Should be updated to:
```yaml
image: wmdailey/hpa-load-tester:latest

You can now apply your Deployment and HP

### How to Use for HPA Testing

1.  **Deploy the application:** Apply the `hpa-test-deployment.yaml` and the hpa-test-hpa.yaml

2.  **Check Status and Release:**
    # Check current memory usage

    curl http://<POD_IP>:8080/status
    http://localhost:8080/status

3.  **Test CPU Scaling:** Send a request that uses more than the target utilization (70% of 250m request):
    # This command hits the pod's CPU hard for 60 seconds

    curl http://<POD_IP>:8080/load?type=cpu&value=60
    http://localhost:8080/load?type=cpu&value=60

    * **Expectation:** The HPA should detect the high CPU utilization (likely near 100%) and scale up the replica count.

4.  **Test Memory Scaling:** Send a request that uses memory beyond the target utilization (80% of 256Mi request is 204.8Mi).
    # This command adds 512MB of memory usage.
    # The application will immediately exceed 80% of the 256Mi request (204.8Mi).

    curl http://<POD_IP>:8080/load?type=memory&value=512
    http://localhost:8080/load?type=memory&value=512

    * **Expectation:** The HPA should detect the high memory utilization and scale up the replica count.

5.  **Check Release:**
    # Release memory for scale-down testing

    curl http://<POD_IP>:8080/status?action=release
    http://localhost:8080/status?action=release
