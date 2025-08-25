Dockerfile:


# Use the official Nginx image as the base image
FROM nginx:latest

# Remove default nginx index file
RUN rm /usr/share/nginx/html/*

# Copy custom HTML files into the container
COPY index.html /usr/share/nginx/html/index.html
COPY app1.html /usr/share/nginx/html/app1.html
COPY app2.html /usr/share/nginx/html/app2.html

# Expose port 80 for the container
EXPOSE 80
