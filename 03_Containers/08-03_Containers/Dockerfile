# Exercise: 07-03 v3.2.0
# Dockerfile for app-frontend

# Cloudera Edu
# 25MAY12
#
# Pull python image from Docker Hub.
# Create a working directory in the image.
# Copy all of the application files into the working directory.
# Upgrade pip
# Read the requirements file and install Flask and libraries.
# Expose port 3000 in the container
# Copy the contents of the working directory,.
# Hardcode the start command
# Set variable for the name of the application file.
# Dockerfile for app-frontend

# Use a stable, recent, and slim Python image for smaller size and security
FROM python:3.12-slim

# Set environment variables for better Python execution in a container
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Create a working directory inside the image
WORKDIR /app

# Copy requirements.txt first and install dependencies. 
# This is a critical build cache optimization. If only the code changes, 
# this layer remains cached and the install doesn't re-run.
COPY app/requirements.txt .

# Install Flask and dependencies. The --no-cache-dir flag is excellent for 
# keeping the final image size small.
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application source code into the working directory
# We assume app.py and the templates directory are now in the root context.
COPY app/. .

# Expose the application port
EXPOSE 3000

# Set the container's main process command (using exec form is best practice)
# ENTRYPOINT sets the executable, and CMD sets the default arguments.
ENTRYPOINT ["python"]
CMD ["app.py"]
