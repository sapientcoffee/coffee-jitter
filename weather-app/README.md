# Weather Data Explorer

This application demonstrates the value of Gemini Cloud Assist Investigations Agent. It is a simple Flask application that queries the `bigquery-public-data:samples.gsod` dataset, stores the results in Cloud SQL, and saves a JSON file to a Cloud Storage bucket.

## Deployment to Cloud Run

Follow these instructions in your Google Cloud Shell or a local terminal with gcloud and Docker installed.

### 1. Set up Your Environment

First, replace the placeholders with your actual project details and create the necessary resources.

```bash
# Set your project and region variables
export PROJECT_ID="your-gcp-project-id"
export REGION="us-central1" # Or your preferred region

# Set names for your resources
export BUCKET_NAME="weather-results-bucket-${PROJECT_ID}"
export SQL_INSTANCE_NAME="weather-db-instance"
export DB_NAME="weather_db"
export DB_USER="weather_user"
export DB_PASS="a-very-secure-password" # Change this!

gcloud config set project ${PROJECT_ID}

# Enable required APIs
gcloud services enable run.googleapis.com \
    sqladmin.googleapis.com \
    storage.googleapis.com \
    bigquery.googleapis.com \
    cloudbuild.googleapis.com \
    artifactregistry.googleapis.com

# Create the Cloud Storage bucket
gcloud storage buckets create gs://${BUCKET_NAME} --location=${REGION}

# Create the Cloud SQL for PostgreSQL instance
gcloud sql instances create ${SQL_INSTANCE_NAME} \
    --database-version=POSTGRES_14 \
    --region=${REGION} \
    --root-password=${DB_PASS}

# Create the database and user within the instance
gcloud sql databases create ${DB_NAME} --instance=${SQL_INSTANCE_NAME}
gcloud sql users create ${DB_USER} --instance=${SQL_INSTANCE_NAME} --password=${DB_PASS}
```

### 2. Build and Push the Docker Image

This command uses Cloud Build to build your container image and push it to Artifact Registry.

```bash
# Build the container image using Cloud Build
gcloud builds submit --tag ${REGION}-docker.pkg.dev/${PROJECT_ID}/weather-app/weather-service:latest
```

### 3. Deploy to Cloud Run

This is the final step. The command deploys your container and securely connects it to your Cloud SQL instance.

```bash
# Get the full instance connection name
INSTANCE_CONNECTION_NAME=$(gcloud sql instances describe ${SQL_INSTANCE_NAME} --format='value(connectionName)')

# Deploy to Cloud Run
gcloud run deploy weather-service \
    --image ${REGION}-docker.pkg.dev/${PROJECT_ID}/weather-app/weather-service:latest \
    --platform managed \
    --region ${REGION} \
    --allow-unauthenticated \
    --add-cloudsql-instances=${INSTANCE_CONNECTION_NAME} \
    --set-env-vars="BUCKET_NAME=${BUCKET_NAME}" \
    --set-env-vars="DB_USER=${DB_USER}" \
    --set-env-vars="DB_PASS=${DB_PASS}" \
    --set-env-vars="DB_NAME=${DB_NAME}" \
    --set-env-vars="INSTANCE_CONNECTION_NAME=${INSTANCE_CONNECTION_NAME}"
```

The deployment process will automatically grant the necessary IAM permissions (Cloud SQL Client, BigQuery User, Storage Object Admin) to the Cloud Run service account.

### 4. Test Your Application

Once deployed, Cloud Run will provide a URL. You can test it by visiting the URL in your browser or using curl:

```bash
# Get the URL of your deployed service
SERVICE_URL=$(gcloud run services describe weather-service --platform managed --region ${REGION} --format 'value(status.url)')

# Call the endpoint for the year 2005
curl -X GET ${SERVICE_URL}/process/2005
```

After running this, you can check your Cloud Storage bucket and your Cloud SQL database to see that the results have been successfully stored.

