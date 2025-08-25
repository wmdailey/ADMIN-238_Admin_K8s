# Dockerfile

# Use a multi-stage build to create a small, efficient final image.

# Stage 1: Build the Go application
FROM golang:1.25-alpine AS builder

# Set the working directory inside the container.
WORKDIR /app

# Copy the go.mod and go.sum files first to take advantage of Docker's layer caching.
# This ensures that dependencies are only re-downloaded if these files change.
COPY app/go.mod ./
COPY app/go.sum ./

# Download all project dependencies.
RUN go mod download

# Copy the rest of the source code.
COPY app .

# Build the application. CGO_ENABLED=0 creates a static binary, which is ideal for
# a minimal final image. We name the output binary 'app'.
RUN CGO_ENABLED=0 go build -o /app/test-cpu ./

# Stage 2: Create the final production image
# We use a minimal base image, `scratch`, which contains nothing but the Go binary.
# This makes the image as small and secure as possible.
FROM scratch

# Set the working directory.
WORKDIR /

# Copy the compiled binary from the builder stage.
COPY --from=builder /app/test-cpu .

# Expose the port the application will run on.
EXPOSE 8080

# Command to run the executable.
CMD ["/test-cpu"]
