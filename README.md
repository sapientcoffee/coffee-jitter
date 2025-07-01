# Coffee Jitter

This project is a simple full-stack application that consists of an Angular frontend and a Go backend. The frontend calls the backend API to display a random coffee pun. The project is designed to be deployed to Google Cloud Run and includes Terraform configuration for infrastructure as code.

## Application Overview

The application is composed of two main components:

*   **Frontend:** An Angular application that displays a coffee pun fetched from the backend.
*   **Backend:** A Go API that serves a random coffee pun from a predefined list.

The application is designed to demonstrate a simple full-stack architecture and deployment to a serverless platform.

## Project Structure

The project is organized into the following directories:

*   `backend`: Contains the Go source code for the backend API.
*   `frontend`: Contains the Angular source code for the frontend application.
*   `terraform`: Contains the Terraform configuration for deploying the application to Google Cloud.

## Local Development

To run the application locally, you will need to have the following installed:

*   [Go](https://golang.org/doc/install)
*   [Node.js and npm](https://nodejs.org/en/download/)
*   [Angular CLI](https://angular.io/cli)

### Backend

1.  Navigate to the `backend` directory:
    ```bash
    cd backend
    ```
2.  Run the backend server:
    ```bash
    go run main.go
    ```
    The server will start on `http://localhost:8080`.

### Frontend

1.  Navigate to the `frontend/frontend` directory:
    ```bash
    cd frontend/frontend
    ```
2.  Install the dependencies:
    ```bash
    npm install
    ```
3.  Start the Angular development server:
    ```bash
    ng serve
    ```
    The frontend will be available at `http://localhost:4200`.

## Cloud Run Deployment

The application can be deployed to Google Cloud Run using either a manual process or an automated process with Infrastructure Manager.

### Manual Deployment

1.  **Build and Push the Backend Image:**
    ```bash
    gcloud builds submit --tag gcr.io/$(gcloud config get-value project)/coffee-pun-backend backend
    ```
2.  **Deploy the Backend Service:**
    ```bash
    gcloud run deploy coffee-pun-backend \
      --image gcr.io/$(gcloud config get-value project)/coffee-pun-backend \
      --platform managed \
      --region us-central1 \
      --allow-unauthenticated
    ```
3.  **Build and Push the Frontend Image:**
    ```bash
    gcloud builds submit --tag gcr.io/$(gcloud config get-value project)/coffee-pun-frontend frontend/frontend
    ```
4.  **Deploy the Frontend Service:**
    ```bash
    gcloud run deploy coffee-pun-frontend \
      --image gcr.io/$(gcloud config get-value project)/coffee-pun-frontend \
      --platform managed \
      --region us-central1 \
      --allow-unauthenticated
    ```

### Automated Deployment with Infrastructure Manager

1.  **Update `cloudbuild.yaml`:**
    Update the `cloudbuild.yaml` file with the correct URL of your git repository.
2.  **Trigger the Deployment:**
    ```bash
    gcloud builds submit --config cloudbuild.yaml .
    ```

## Terraform

The `terraform` directory contains the Terraform configuration for provisioning the necessary infrastructure for the application. To use it, you will need to have [Terraform](https://www.terraform.io/downloads.html) installed.

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

## Demo Scenario

The application includes a demo scenario that simulates a memory leak in the backend and high latency in the frontend.

*   **Backend:** The backend is configured to continuously allocate memory in the background, which will eventually cause it to crash.
*   **Frontend:** The frontend is configured to retry connecting to the backend if it's down, and the timeout will simulate high latency.

This scenario is designed to demonstrate how to troubleshoot and debug issues in a distributed application.
