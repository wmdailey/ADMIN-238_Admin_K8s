#!/bin/sh

set -e

echo "Running pre-startup tasks..."
/app/log_start.sh &

echo "Starting Flask app..."
exec python /app/web-traffic-counter.py
