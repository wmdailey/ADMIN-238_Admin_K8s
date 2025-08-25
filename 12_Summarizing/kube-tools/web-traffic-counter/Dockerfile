# Dockerfile

# Use a base Python image
FROM python:3.9-slim-buster

# Set the working directory in the container
WORKDIR /app

# Copy requirements.txt and install dependencies
COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code
COPY  app .

# Make the startup script executable
RUN chmod +x /app/startup.sh
RUN chmod +x /app/log_start.sh
RUN chmod +x /app/log_stop.sh

# Copy sources list
COPY sources.list /etc/apt/sources.list

# Create log file
RUN echo "URL request: 0" > /var/log/backend.log

# Expose the port your Flask app will run on
EXPOSE 5000

# Use ENTRYPOINT to specify the main command
ENTRYPOINT ["./startup.sh"]

# Define the command to run your Flask application
#CMD ["python", "web-traffic-counter.py"]
CMD []
