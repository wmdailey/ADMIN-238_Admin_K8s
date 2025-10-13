# --- Stage 1: Build the Go binary ---
FROM golang:1.21-alpine AS builder

# Set necessary environment variables
ENV CGO_ENABLED=0
ENV GOOS=linux
ENV GOARCH=amd64
#ENV GOARCH=arm64 # If running on the macOS

# Set the working directory
WORKDIR /app

# Copy the Go application source code
COPY app/main.go .

# Build the application, statically linked, outputting a binary named 'hpa-load-tester'
RUN go build -ldflags "-w -s" -o k8s-scale-test main.go

# --- Stage 2: Create the minimal production image ---
FROM alpine:latest

# Expose the port defined in your Deployment (8080)
EXPOSE 8080

# Set the entrypoint to the static binary from the builder stage
WORKDIR /root/
COPY --from=builder /app/k8s-scale-test .

# Run the application
ENTRYPOINT ["./k8s-scale-test"]
