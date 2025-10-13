# Use a slim Python base image to keep the container small.
FROM python:3.9-slim-buster

# Install socat, which will be used to proxy connections to our Python script.
# socat is a powerful utility for relaying data between two locations.
RUN apt-get update && apt-get install -y socat && rm -rf /var/lib/apt/lists/*

# Copy the Python script into the container.
# This script will act as our "server logic".
COPY server.py /server.py

# Expose the port where socat will listen for incoming connections.
EXPOSE 5000

# This is the core command that starts the server.
# It tells socat to:
# 1. Listen on TCP port 5000 on all interfaces (TCP-LISTEN:5000,fork,reuseaddr).
# 2. For each incoming connection, it will "fork" a new process.
# 3. This forked process will then execute the `python3 /server.py` command.
# 4. The `stdio` part links the client's input/output to the Python script's stdin/stdout.
CMD ["socat", "TCP-LISTEN:5000,fork,reuseaddr", "EXEC:\"python3 /server.py\",pty,stderr"]
