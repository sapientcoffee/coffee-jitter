# Use an official lightweight Python image.
FROM python:3.11-slim

# Set the working directory in the container
WORKDIR /app

# Copy the dependencies file and install them
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code
COPY . .

# Gunicorn is a production-ready web server.
# The PORT environment variable is automatically set by Cloud Run.
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "main:app"]
