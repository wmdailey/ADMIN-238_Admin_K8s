# --- Stage 1: Build the Go binary ---
# Use a robust Go image for compilation
FROM golang:1.21-alpine AS builder

# Set environment variables for static compilation on Linux/AMD64
ENV CGO_ENABLED=0
ENV GOOS=linux
# Note: Assuming standard AMD64 architecture. If using Apple Silicon (M1/M2/M3), 
# consider setting ENV GOARCH=arm64 for optimized performance.

# Set the working directory inside the container
WORKDIR /app

# Copy the Go application source code (assuming it's named health_probe.go)
COPY app/main.go . 

# Build the Go binary
# CGO_ENABLED=0 is important for creating a statically linked binary, which is ideal for a scratch image
RUN go mod init edu-health-probe || true
RUN go mod tidy
RUN CGO_ENABLED=0 go build -o /edu-health-probe
RUN go build -ldflags "-w -s" -o edu-health-probe main.go

# --- Stage 2: Create the minimal production image ---
# Use a minimal base image (Scratch or Alpine) for the smallest footprint
FROM alpine:latest

# Expose the port used by the Go application (8080)
EXPOSE 8080

# Set the entrypoint to the static binary from the builder stage
WORKDIR /root/
# Copy the compiled binary from the builder stage
COPY --from=builder /app/edu-health-probe .

# Run the application
ENTRYPOINT ["./edu-health-probe"]
