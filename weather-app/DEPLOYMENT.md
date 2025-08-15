# 🚀 Deploying the Weather App: A Coffee-Powered Guide 🚀

Welcome, intrepid developer! Grab your favorite mug of joe ☕️, and let's get this weather app brewing on Cloud Run. This guide will walk you through the steps to get your application live, even if you're not fully caffeinated yet.

## 📜 What You'll Need

*   A Google Cloud project to host your App Hub application (the "host project").
*   A Google Cloud project to deploy your application resources (the "service project"). For this guide, we'll use `coffee-jitters`.
*   The `gcloud` CLI installed and authenticated.
*   Docker installed and configured.
*   A strong love for coffee (optional, but highly recommended).

## 部署 (Deployment Steps)

### 1. ☕️ Perk Up Your Environment

First things first, we need to get our environment ready. It's like grinding the beans before you brew!

We'll set some environment variables and enable the necessary APIs. Don't worry, it's less painful than a decaf Monday.

```bash
# Set your project and region variables
export PROJECT_ID="your-gcp-project-id" # 👈 Change this to your project ID!
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
    artifactregistry.googleapis.com \
    apphub.googleapis.com
```

### 2.  Hub for Your Brews (App Hub)

Let's create an App Hub application to keep all our resources nicely organized. It's like having a well-organized coffee station.

```bash
gcloud apphub applications create weather-and-coffee \
    --display-name="Weather & Coffee" \
    --location=${REGION} \
    --project=${PROJECT_ID} \
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
```

### 3. 🪣 Create a Bucket for Your Beans (Data)

We need a place to store our weather data. Think of it as a giant coffee bean silo.

```bash
gcloud storage buckets create gs://${BUCKET_NAME} --location=${REGION}
```

### 4. 🐘 A Database to Store Your Brews (Queries)

Next, we'll create a Cloud SQL for PostgreSQL instance. This is where we'll keep track of all our important weather queries.

```bash
gcloud sql instances create ${SQL_INSTANCE_NAME} \
    --database-version=POSTGRES_14 \
    --region=${REGION} \
    --root-password=${DB_PASS} \
    --tier=db-g1-small # A nice, cozy tier for our database.
```

Once the instance is ready (it might take a few minutes, so grab another coffee ☕️), we'll create the database and a user.

```bash
gcloud sql databases create ${DB_NAME} --instance=${SQL_INSTANCE_NAME}
gcloud sql users create ${DB_USER} --instance=${SQL_INSTANCE_NAME} --password=${DB_PASS}
```

### 5. 🐳 Build and Push Your Docker Image

Now it's time to containerize our application. We'll use Cloud Build to create a Docker image and push it to Artifact Registry. It's like a high-tech coffee roaster!

First, we need to create a repository in Artifact Registry:

```bash
gcloud artifacts repositories create weather-app \
    --repository-format=docker \
    --location=${REGION} \
    --description="Weather App repository"
```

Then, we can build and push the image:

```bash
gcloud builds submit --tag ${REGION}-docker.pkg.dev/${PROJECT_ID}/weather-app/weather-service:latest weather-app
```

### 6. 🚀 Deploy to Cloud Run!

The moment of truth! We're ready to deploy our application to Cloud Run. This is the final pour.

```bash
# Get the full instance connection name
INSTANCE_CONNECTION_NAME=$(gcloud sql instances describe ${SQL_INSTANCE_NAME} --format='value(connectionName)')

# Deploy!
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

### 7. 📝 Register Your Services and Workloads

Now that our resources are deployed, let's register them with our App Hub application.

First, we need to find the unique ID of our discovered `weather-service`.

```bash
gcloud apphub discovered-services list \
    --filter='serviceReference="//run.googleapis.com/projects/${SERVICE_PROJECT_ID}/locations/us-central1/services/weather-service"' \
    --project=${HOST_PROJECT_ID} \
    --location=us-central1
```

Once you have the ID, you can register the service:

```bash
gcloud apphub applications services create weather-service \
    --application=weather-and-coffee \
    --location=us-central1 \
    --project=${HOST_PROJECT_ID} \
    --discovered-service="projects/${HOST_PROJECT_ID}/locations/us-central1/discoveredServices/YOUR_DISCOVERED_SERVICE_ID" \
    --display-name="Weather Service"
```

Next, we'll do the same for our Cloud SQL instance, which is a "workload" in App Hub.

```bash
gcloud apphub discovered-workloads list \
    --filter='workloadReference="//cloudsql.googleapis.com/projects/${SERVICE_PROJECT_ID}/instances/weather-db-instance"' \
    --project=${HOST_PROJECT_ID} \
    --location=us-central1
```

And register it:

```bash
gcloud apphub applications workloads create weather-db-instance \
    --application=weather-and-coffee \
    --location=us-central1 \
    --project=${HOST_PROJECT_ID} \
    --discovered-workload="projects/${HOST_PROJECT_ID}/locations/us-central1/discoveredWorkloads/YOUR_DISCOVERED_WORKLOAD_ID" \
    --display-name="Weather DB Instance"
```

### 8. 🎉 Taste Your Creation!

Congratulations! Your weather app is now deployed and registered. You can test it with a simple `curl` command.

```bash
# Get the URL of your deployed service
SERVICE_URL=$(gcloud run services describe weather-service --platform managed --region ${REGION} --format 'value(status.url)')

# Call the endpoint for the year 2005
curl -X GET ${SERVICE_URL}/past/2005
```

Now, sit back, relax, and enjoy your freshly deployed application. You've earned it! ☕️
