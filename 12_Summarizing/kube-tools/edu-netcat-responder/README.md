Building and Running the Image
1. Save the Dockerfile: Save the code above in a file named Dockerfile.

2. Build the image: Open a terminal in the same directory and run the following command to build your custom image.

	docker build -t netcat-responder .

3. Run the container: Run the image and map your local port (e.g., 5000) to the container's port 5000.

	docker run --rm -p 5000:5000 netcat-responder

* --rm: This flag automatically removes the container when it exits.

* -p 5000:5000: This publishes the container's port 5000 to the host's port 5000, making it accessible from your host machine.

4. Tag 

	docker tag netcat-responder wmdailey/k8s-netcat-responder:latest

5. Push to the Docker Hub Repo

	docker push wmdailey/k8s-netcat-responder:latest


