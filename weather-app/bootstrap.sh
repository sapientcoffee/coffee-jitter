#!/bin/bash

# 🚀 Welcome to the Weather App Bootstrap Script! 🚀
# This script is designed to get your environment set up faster than a double shot of espresso.
# So grab your favorite mug, and let's get brewing! ☕️

# --- Configuration ---
# 👇 Feel free to change these values, but don't spill your coffee on the keyboard!
export HOST_PROJECT_ID="google-mpf-958521849590" # Your App Hub host project ID
export SERVICE_PROJECT_ID="coffee-jitters" # Your service project ID
export REGION="us-central1" # The region where you want to deploy
export DB_PASS="a-very-secure-password" # 🤫 Psst! Change this to a real password!

# --- Script Starts Here ---

echo "👋 Howdy, coffee lover! Let's get this weather app deployed."
echo "Setting project to ${SERVICE_PROJECT_ID}..."
gcloud config set project ${SERVICE_PROJECT_ID}

echo " waking up the gnomes that run the Google Cloud APIs... 🧙‍♂️"
gcloud services enable run.googleapis.com \
    sqladmin.googleapis.com \
    storage.googleapis.com \
    bigquery.googleapis.com \
    cloudbuild.googleapis.com \
    artifactregistry.googleapis.com \
    apphub.googleapis.com

echo "\nLet's create an App Hub application to keep things tidy... ☕️"
gcloud apphub applications create weather-and-coffee \
    --display-name="Weather & Coffee" \
    --location=${REGION} \
    --project=${HOST_PROJECT_ID} \
    --scope-type=REGIONAL \
    --business-owners="email=ceo@cymbal.coffee" \
    --business-owners="email=vp-of-vibes@cymbal.coffee" \
    --developer-owners="email=lead-barista@cymbal.coffee" \
    --developer-owners="email=full-stack-roaster@cymbal.coffee" \
    --operator-owners="email=devops-drip@cymbal.coffee" \
    --operator-owners="email=sre-steam@cymbal.coffee" \
    --operator-owners="email=chief-of-steam@cymbal.coffee" \
    --criticality-type=HIGH \
    --environment-type=PRODUCTION

echo "\nCreating a Cloud Storage bucket. Think of it as a giant coffee bean silo... 🪣"
export BUCKET_NAME="weather-results-bucket-${SERVICE_PROJECT_ID}"
gcloud storage buckets create gs://${BUCKET_NAME} --location=${REGION}

echo "\nNow, let's brew up a Cloud SQL instance. This might take a few minutes, so maybe grab another coffee? ☕️"
export SQL_INSTANCE_NAME="weather-db-instance"
gcloud sql instances create ${SQL_INSTANCE_NAME} \
    --database-version=POSTGRES_14 \
    --region=${REGION} \
    --root-password=${DB_PASS} \
    --tier=db-g1-small

echo "\nInstance created! Now, let's create the database and a user. It's like adding sugar and cream... 🥛"
export DB_NAME="weather_db"
export DB_USER="weather_user"
gcloud sql databases create ${DB_NAME} --instance=${SQL_INSTANCE_NAME}
gcloud sql users create ${DB_USER} --instance=${SQL_INSTANCE_NAME} --password=${DB_PASS}

echo "\nTime to create a home for our Docker image in Artifact Registry. It's like a cozy little coffee shop for our container... 🏠"
gcloud artifacts repositories create weather-app \
    --repository-format=docker \
    --location=${REGION} \
    --description="Weather App repository"

echo "\nBuilding and pushing the Docker image. This is where the magic happens! ✨"
gcloud builds submit --tag ${REGION}-docker.pkg.dev/${SERVICE_PROJECT_ID}/weather-app/weather-service:latest weather-app

echo "\nThe final pour! Deploying the application to Cloud Run... 🚀"
export INSTANCE_CONNECTION_NAME=$(gcloud sql instances describe ${SQL_INSTANCE_NAME} --format='value(connectionName)')
gcloud run deploy weather-service \
    --image ${REGION}-docker.pkg.dev/${SERVICE_PROJECT_ID}/weather-app/weather-service:latest \
    --platform managed \
    --region ${REGION} \
    --allow-unauthenticated \
    --add-cloudsql-instances=${INSTANCE_CONNECTION_NAME} \
    --set-env-vars="BUCKET_NAME=${BUCKET_NAME}" \
    --set-env-vars="DB_USER=${DB_USER}" \
    --set-env-vars="DB_PASS=${DB_PASS}" \
    --set-env-vars="DB_NAME=${DB_NAME}" \
    --set-env-vars="INSTANCE_CONNECTION_NAME=${INSTANCE_CONNECTION_NAME}"

echo "\nNow, let's register our new service and workload with App Hub. It's like putting a fancy label on our coffee blend... 🏷️"

# Wait for the service to be discovered
echo " waiting for the Cloud Run service to be discovered by App Hub..."
while [[ -z "$(gcloud apphub discovered-services list --project=${HOST_PROJECT_ID} --location=${REGION} --filter='serviceReference="//run.googleapis.com/projects/${SERVICE_PROJECT_ID}/locations/us-central1/services/weather-service"' --format='value(ID)')" ]]; do
    echo " still waiting for the service to be discovered..."
    sleep 10
done

SERVICE_ID=$(gcloud apphub discovered-services list --project=${HOST_PROJECT_ID} --location=${REGION} --filter='serviceReference="//run.googleapis.com/projects/${SERVICE_PROJECT_ID}/locations/us-central1/services/weather-service"' --format='value(ID)')
echo " service discovered! ID: ${SERVICE_ID}"

gcloud apphub applications services create weather-service \
    --application=weather-and-coffee \
    --location=${REGION} \
    --project=${HOST_PROJECT_ID} \
    --discovered-service="projects/${HOST_PROJECT_ID}/locations/${REGION}/discoveredServices/${SERVICE_ID}" \
    --display-name="Weather Service"

# Wait for the workload to be discovered
echo " waiting for the Cloud SQL instance to be discovered by App Hub..."
while [[ -z "$(gcloud apphub discovered-workloads list --project=${HOST_PROJECT_ID} --location=${REGION} --filter='workloadReference="//cloudsql.googleapis.com/projects/${SERVICE_PROJECT_ID}/instances/weather-db-instance"' --format='value(ID)')" ]]; do
    echo " still waiting for the workload to be discovered..."
    sleep 10
done

WORKLOAD_ID=$(gcloud apphub discovered-workloads list --project=${HOST_PROJECT_ID} --location=${REGION} --filter='workloadReference="//cloudsql.googleapis.com/projects/${SERVICE_PROJECT_ID}/instances/weather-db-instance"' --format='value(ID)')
echo " workload discovered! ID: ${WORKLOAD_ID}"

gcloud apphub applications workloads create weather-db-instance \
    --application=weather-and-coffee \
    --location=${REGION} \
    --project=${HOST_PROJECT_ID} \
    --discovered-workload="projects/${HOST_PROJECT_ID}/locations/${REGION}/discoveredWorkloads/${WORKLOAD_ID}" \
    --display-name="Weather DB Instance"

echo "\n🎉 Success! Your weather app is now live and registered in App Hub! 🎉"
export SERVICE_URL=$(gcloud run services describe weather-service --platform managed --region ${REGION} --format 'value(status.url)')
echo "You can test it with the following command:"
echo "curl -X GET ${SERVICE_URL}/past/2005"
echo "\nEnjoy your freshly deployed application! ☕️"
