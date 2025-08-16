#!/bin/bash

# 🚀 Welcome to the Weather App Bootstrap Script! 🚀
# This script is designed to get your environment set up faster than a double shot of espresso.
# It will prepare all the necessary infrastructure for your CI/CD pipeline.
# So grab your favorite mug, and let's get brewing! ☕️

# --- Configuration ---
# 👇 Feel free to change these values, but don't spill your coffee on the keyboard!
export HOST_PROJECT_ID="google-mpf-958521849590" # Your App Hub host project ID
export SERVICE_PROJECT_ID="coffee-jitters" # Your service project ID
export REGION="us-central1" # The region where you want to deploy
export DB_PASS="a-very-secure-password" # 🤫 Psst! Change this to a real password!
export USER_EMAIL="admin@robedwards.altostrat.com" # Your email address

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
    apphub.googleapis.com \
    clouddeploy.googleapis.com \
    containeranalysis.googleapis.com

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

echo "\nSetting up our sophisticated, multi-stage deployment pipeline... ☕️"
gcloud deploy apply --file=weather-app/cicd/clouddeploy.yaml --region=us-central1 --project=coffee-jitters

echo "\nGranting the necessary permissions to our trusty Cloud Build service account..."
export PROJECT_NUMBER=$(gcloud projects describe ${SERVICE_PROJECT_ID} --format='value(projectNumber)')
gcloud projects add-iam-policy-binding ${SERVICE_PROJECT_ID} \
    --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
    --role="roles/clouddeploy.releaser" \
    --condition=None
gcloud projects add-iam-policy-binding ${SERVICE_PROJECT_ID} \
    --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
    --role="roles/run.developer" \
    --condition=None
gcloud projects add-iam-policy-binding ${SERVICE_PROJECT_ID} \
    --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
    --role="roles/iam.serviceAccountUser" \
    --condition=None
gcloud projects add-iam-policy-binding ${SERVICE_PROJECT_ID} \
    --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
    --role="roles/logging.logWriter" \
    --condition=None
gcloud projects add-iam-policy-binding ${SERVICE_PROJECT_ID} \
    --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
    --role="roles/cloudbuild.builds.editor" \
    --condition=None

gcloud projects add-iam-policy-binding ${SERVICE_PROJECT_ID} \
    --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
    --role="roles/storage.admin" \
    --condition=None
gcloud projects add-iam-policy-binding ${SERVICE_PROJECT_ID} \
    --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
    --role="roles/containeranalysis.admin" \
    --condition=None
gcloud projects add-iam-policy-binding ${SERVICE_PROJECT_ID} \
    --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
    --role="roles/clouddeploy.viewer" \
    --condition=None

echo "\nAnd of course, we need to make sure you can see the logs... 🕵️"
gcloud projects add-iam-policy-binding ${SERVICE_PROJECT_ID} \
    --member="user:${USER_EMAIL}" \
    --role="roles/logging.viewer" \
    --condition=None
gcloud projects add-iam-policy-binding ${SERVICE_PROJECT_ID} \
    --member="user:${USER_EMAIL}" \
    --role="roles/logging.privateLogViewer" \
    --condition=None

echo "\n🎉 Success! Your infrastructure is ready. 🎉"
echo "The final steps are manual:"
echo "1. Connect your Git repository to Cloud Build in the Google Cloud Console."
echo "2. Create a Cloud Build trigger for the 'main' branch."

echo "\nEnjoy your freshly brewed CI/CD pipeline! ☕️"