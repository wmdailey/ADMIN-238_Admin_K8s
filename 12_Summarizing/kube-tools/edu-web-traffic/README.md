#Web Traffic Counter  Tool

## Getting Started

### Prerequisites

To use the test-cpu, you need to have the following installed:

Python (version x or higher)
Docker

### Running with Docker

1. Build the Docker image using the provided Dockerfile:
	docker build -t edu-web-traffic-counter .

2. Start port forwarding
	kubectl port-forward pod/web-traffic-counter-xxx 8080:8080

2. Run the Docker container, specifying the desired CPU usage, stress duration, and optionally whether to run CPU stress indefinitely:
       docker run -p 8080:8080 edu-web-traffic-counter

  	URL: http://localhost:8080
  	URL: http://localhost:8080/log-stop.sh
  	URL: http://localhost:8080/log-start.sh
	Ctrl-C

3. Retag for Docker Hub
	docker tag edu-web-traffic-counter wmdailey/edu-web-traffic-counter:latest

4. Login to Docker Hub
	docker login

5. Push the image into Docker Hub.
	docker push wmdailey/edu-web-traffic-counter:latest

