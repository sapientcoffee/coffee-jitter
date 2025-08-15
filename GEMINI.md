# GEMINI.md - Your AI Assistant's Context

This file provides context to the Gemini AI assistant to help it understand your project.

## Project Overview

This is a full-stack web application consisting of an Angular frontend and a Go backend. The application is designed to be deployed on Google Cloud Run. The backend serves random coffee puns to the frontend. The project also includes a demo scenario that simulates a memory leak in the backend and high latency in the frontend, making it a good candidate for troubleshooting and debugging exercises.

### Key Technologies

*   **Frontend:** Angular
*   **Backend:** Go
*   **Deployment:** Docker, Google Cloud Run
*   **Infrastructure as Code:** Terraform

## Building and Running

### Local Development

**Backend:**

```bash
cd backend
go run main.go
```

The backend will be available at `http://localhost:8080`.

**Frontend:**

```bash
cd frontend/frontend
npm install
ng serve
```

The frontend will be available at `http://localhost:4200`.

### Cloud Run Deployment

The application can be deployed to Google Cloud Run using the gcloud CLI or automatically with Google Cloud Build.

#### Manual Deployment

**Build and Push Backend Image:**

```bash
gcloud builds submit --tag gcr.io/$(gcloud config get-value project)/coffee-pun-backend backend
```

**Deploy Backend Service:**

```bash
gcloud run deploy coffee-pun-backend \
  --image gcr.io/$(gcloud config get-value project)/coffee-pun-backend \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated
```

**Build and Push Frontend Image:**

```bash
gcloud builds submit --tag gcr.io/$(gcloud config get-value project)/coffee-pun-frontend frontend/frontend
```

**Deploy Frontend Service:**

```bash
gcloud run deploy coffee-pun-frontend \
  --image gcr.io/$(gcloud config get-value project)/coffee-pun-frontend \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated
```

#### Automated Deployment

The project is configured to be deployed automatically with Google Cloud Build and Infrastructure Manager. The `cloudbuild.yaml` file defines the deployment pipeline. To trigger the deployment, run the following command:

```bash
gcloud builds submit --config cloudbuild.yaml .
```

## Terraform

The `terraform` directory contains the Terraform configuration for provisioning the necessary infrastructure for the application. The configuration does the following:

*   Enables the Cloud Build, Cloud Run, Artifact Registry, and Monitoring APIs.
*   Creates a gcr.io container registry.
*   Grants the Cloud Build service account the necessary IAM roles to push to the container registry.
*   Deploys the backend and frontend services to Cloud Run.
*   Makes the Cloud Run services publicly accessible.
*   Creates a monitoring uptime check for the frontend service.

To use the Terraform configuration, you will need to have [Terraform](https://www.terraform.io/downloads.html) installed.

1.  **Initialize Terraform:**
    ```bash
    cd terraform
    terraform init
    ```
2.  **Update `terraform.tfvars`:**
    Update the `terraform.tfvars` file with your Google Cloud project ID and Cloud Build service account.
3.  **Apply the Configuration:**
    ```bash
    terraform apply
    ```

## Development Conventions

*   The backend is written in Go and the frontend is written in Angular.
*   The application is designed to be deployed to Google Cloud Run.
*   Terraform is used for infrastructure as code.
*   The backend is containerized using a multi-stage Dockerfile for a small and secure image.

## New Application: Weather Data Explorer

This new application will demonstrate the value of Gemini Cloud Assist Investigations Agent. It is a simple Flask application that queries the `bigquery-public-data:samples.gsod` dataset, stores the results in Cloud SQL, and saves a JSON file to a Cloud Storage bucket.

The application code and deployment instructions can be found in the `weather-app` directory.

### Architecture

*   **Backend:** A Cloud Run service that will query the BigQuery `gsod` dataset.
*   **Database:** Cloud SQL will be used to store user-defined queries or application state.
*   **Storage:** Cloud Storage will be used to store exported data or generated reports from the BigQuery queries.

## Gemini Cloud Assist Investigations Supported Products

*   App Hub
*   Cloud SQL
*   Cloud Storage
*   Compute Engine
*   Google Kubernetes Engine
*   Cloud Networking
*   Cloud Run
*   Dataproc on Compute Engine
*   Google Cloud Serverless for Apache Spark
*   Pub/Sub
*   BigQuery
*   Bigtable
*   Cloud Composer
*   Dataflow
*   Spanner
*   Memorystore for Redis
*   Identity and Access Management
*   Cloud Quotas

## App Hub Supported Resources

*   AlloyDB for PostgreSQL
*   Bigtable
*   Cloud Data Fusion
*   Cloud Deploy
*   Cloud Load Balancing
*   Cloud Logging
*   Cloud Run
*   Cloud SQL
*   Cloud Storage
*   Dataproc Metastore
*   Firestore
*   Google Kubernetes Engine (GKE)
*   Managed Service for Microsoft Active Directory
*   Memorystore for Redis
*   Pub/Sub
*   Secret Manager
*   Spanner
*   Vertex AI
*   Compute Engine
