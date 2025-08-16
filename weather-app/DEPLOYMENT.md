# 🚀 Deploying the Weather App: A Coffee-Powered Guide 🚀

Welcome, intrepid developer! This guide provides two methods for deploying the Weather App: a quick manual deployment and a more robust, automated CI/CD pipeline.

---

## ☕️ Method 1: Manual Deployment (The Quick Espresso Shot)

This method is great for a fast, one-off deployment to get your application running quickly.

### 1. Perk Up Your Environment

```bash
# Set your project and region variables
export PROJECT_ID="coffee-jitters" # 👈 This is our service project
export REGION="us-central1"

# Set names for your resources
export BUCKET_NAME="weather-results-bucket-${PROJECT_ID}"
export SQL_INSTANCE_NAME="weather-db-instance"
export DB_NAME="weather_db"
export DB_USER="weather_user"
export DB_PASS="a-very-secure-password" # 🤫 Change this to a real password!

gcloud config set project ${PROJECT_ID}

# Enable the magic! (a.k.a. the APIs)
gcloud services enable run.googleapis.com \
    sqladmin.googleapis.com \
    storage.googleapis.com \
    bigquery.googleapis.com \
    cloudbuild.googleapis.com \
    artifactregistry.googleapis.com
```

### 2. Create a Bucket and Database

```bash
gcloud storage buckets create gs://${BUCKET_NAME} --location=${REGION}

gcloud sql instances create ${SQL_INSTANCE_NAME} \
    --database-version=POSTGRES_14 \
    --region=${REGION} \
    --root-password=${DB_PASS} \
    --tier=db-g1-small

gcloud sql databases create ${DB_NAME} --instance=${SQL_INSTANCE_NAME}
gcloud sql users create ${DB_USER} --instance=${SQL_INSTANCE_NAME} --password=${DB_PASS}
```

### 3. Build and Deploy

```bash
gcloud artifacts repositories create weather-app \
    --repository-format=docker \
    --location=${REGION} \
    --description="Weather App repository"

gcloud builds submit --tag ${REGION}-docker.pkg.dev/${PROJECT_ID}/weather-app/weather-service:latest weather-app

INSTANCE_CONNECTION_NAME=$(gcloud sql instances describe ${SQL_INSTANCE_NAME} --format='value(connectionName)')

gcloud run deploy weather-service \
    --image ${REGION}-docker.pkg.dev/${PROJECT_ID}/weather-app/weather-service:latest \
    --platform managed \
    --region ${REGION} \
    --allow-unauthenticated \
    --add-cloudsql-instances=${INSTANCE_CONNECTION_NAME} \
    --set-env-vars="BUCKET_NAME=${BUCKET_NAME},DB_USER=${DB_USER},DB_PASS=${DB_PASS},DB_NAME=${DB_NAME},INSTANCE_CONNECTION_NAME=${INSTANCE_CONNECTION_NAME},PROJECT_ID=${PROJECT_ID}"
```

---

## 🚀 Method 2: Automated CI/CD Pipeline (The Perfect Pour Over)

This method sets up a sophisticated, multi-stage CI/CD pipeline powered by Cloud Build and Cloud Deploy. The pipeline is triggered by a push to the `main` branch of your Git repository.

### 1. Run the Bootstrap Script

The `bootstrap.sh` script will set up all the necessary infrastructure for your pipeline, including the App Hub application, GCS bucket, Cloud SQL instance, and Artifact Registry repository. It will also grant the necessary IAM permissions to the Cloud Build service account and your user account.

```bash
./weather-app/bootstrap.sh
```

### 2. Connect Your Git Repository

This is a **manual step** that you must do in the Google Cloud Console. Connect your Git repository (e.g., GitHub) to Cloud Build in your `coffee-jitters` project.

*   Follow this guide: [Connect to a GitHub repository](https://cloud.google.com/build/docs/automating-builds/create-github-app-triggers#connect_repo)

### 3. Create the Cloud Build Trigger

Once your repository is connected, create the Cloud Build trigger. Make sure to replace the repository and connection names with your own.

```bash
gcloud builds triggers create github \
    --name="weather-app-main-branch-trigger" \
    --repository="projects/coffee-jitters/locations/us-central1/connections/YOUR_CONNECTION_NAME/repositories/YOUR_REPO_NAME" \
    --branch-pattern="^main$" \
    --build-config="weather-app/cicd/cloudbuild.yaml" \
    --project="coffee-jitters" \
    --region="us-central1"
```

### 4. Push to Git and Watch the Magic!

Now, all you need to do is commit and push your changes to the `main` branch. This will trigger the pipeline, which will build your image, create a release, and deploy it to the "taste" (testing) environment. After a successful deployment to "taste", the pipeline will automatically proceed to the "serve" (production) environment, which will deploy to both the US and Europe.

Enjoy your automated, coffee-powered CI/CD pipeline! ☕️
