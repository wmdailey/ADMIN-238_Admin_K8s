This solution provides a complete load generation tool.

### How to Build 

# Step 1: Compile the Go Application (Optional but Recommended)
While the Dockerfile handles compilation, running this command locally ensures the code compiles correctly for the target Linux environment:
# Compile for Linux (the target OS inside the container)

cd app
CGO_ENABLED=0 GOOS=linux 
go build -o edu-autoscaler main.go

# Step 2: Build the Docker Image
Use the `docker build` command to execute the steps in the `Dockerfile`. You must tag the image to match the format you plan to use in the Canvas.
Using the application name from your selected text in the Canvas (`scale-test`):
# Use 'wmdailey' with your Docker Hub username or registry prefix
# Replace 'latest' with a version tag (e.g., v1.0.0)

cd ..
docker build -t wmdailey/edu-autoscaler:latest .

# Step 3: Push the Image to a Registry
For Kubernetes (especially managed services like GKE or EKS) to access the image, it must be pushed to a public or private container registry.

docker push wmdailey/edu-autoscaler:latest

# Step 4: Update the Canvas
Finally, update the Deployment section in your Canvas file (`hpa-test-deployment.yaml`) with the full image path you just pushed (from Step 2).
The line you selected:
image: <YOUR-IMAGE-PATH> # Replace with your built Go application image

Should be updated to:
image: wmdailey/edu-autoscaler:latest
You can now apply your Deployment and HP

# Step 5: Setup

kubectl apply -f autoscaler-deploy.yaml -f autoscaler-hpa.yaml
kubectl port-forward service/autoscaler-svc 8080:8080

### How to Use for HPA Testing

# 1.  **Deploy the application:** Apply the `hpa-test-deployment.yaml` and the hpa-test-hpa.yaml
The curl command can be run from a Pod. The http URL can be run from a browser.

# 2.  **Check Status and Release:**
    # Check current memory usage

    curl http://<SERVICE_DNS>:8080/status
    http://localhost:8080/status

# 3.  **Test CPU Scaling:** Send a request that uses more than the target utilization (70% of 250m request):
    # This command hits the pod's CPU hard for 60 seconds

    curl http://<SERVICE_DNS>:8080/load?type=cpu&value=60&cores=1
    http://localhost:8080/load?type=cpu&value=60&cores=1

    * **Expectation:** The HPA should detect the high CPU utilization (likely near 100%) and scale up the replica count.

# 4.  **Test Memory Scaling:** Send a request that uses memory beyond the target utilization (80% of 256Mi request is 204.8Mi).
    # This command adds 512MB of memory usage.
    # The application will immediately exceed 80% of the 256Mi request (204.8Mi).

    curl http://<SERVICE_DNS>:8080/load?type=memory&value=512
    http://localhost:8080/load?type=memory&value=512

    * **Expectation:** The HPA should detect the high memory utilization and scale up the replica count.

# 5.  **Check Release:**
    # Release memory for scale-down testing

    curl http://<SERVICE_DNS>:8080/status?action=release
    http://localhost:8080/status?action=release

### Using kubectl logs (Most Common):
This command fetches the logs directly from the running container in your specified Pod.

# 1. Find the name of the running Pod in your namespace

     kubectl get pods -n <NAMESPACE>

# 2. View the logs for that Pod

     kubectl logs <POD_NAME> -n <NAMESPACE>

# 3. Using kubectl logs -f (Follow/Tail Logs): To see logs in real-time (useful when you are actively testing or stressing the app), use the -f flag (for "follow"):

     kubectl logs -f <POD_NAME> -n <NAMESPACE>
