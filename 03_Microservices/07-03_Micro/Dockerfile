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

FROM python:3.14-rc-slim

WORKDIR /app

COPY app/. . 

RUN pip install --upgrade pip

RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 3000

ENTRYPOINT ["python"]

CMD ["app.py"]
