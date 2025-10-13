# Start from a minimal, lightweight base image like Alpine Linux
FROM alpine:latest

# Install netcat (part of the busybox package in Alpine)
RUN apk --no-cache add busybox-extras

# Expose the port you want to listen on
EXPOSE 5000

# Run netcat in listen mode, responding to a single connection,
# and redirecting a static message to the client.
CMD while true; do echo "Response from the netcat container!" | nc -l -p 5000; done
