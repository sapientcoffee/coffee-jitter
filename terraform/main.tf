terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.50.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_project_service" "cloudbuild" {
  service = "cloudbuild.googleapis.com"
}

resource "google_project_service" "cloudrun" {
  service = "run.googleapis.com"
}

resource "google_project_service" "artifactregistry" {
  service = "artifactregistry.googleapis.com"
}

resource "google_artifact_registry_repository" "gcr_repo" {
  provider      = google
  location      = var.region
  repository_id = "gcr.io"
  description   = "gcr.io container registry"
  format        = "DOCKER"
  depends_on = [
    google_project_service.artifactregistry
  ]
}

resource "google_project_iam_member" "cloudbuild_storage_viewer" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${var.cloudbuild_service_account}"
}

resource "google_project_iam_member" "cloudbuild_artifact_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${var.cloudbuild_service_account}"
}

resource "google_cloud_run_v2_service" "backend" {
  name     = "coffee-pun-backend-tf"
  location = var.region

  template {
    containers {
      image = "gcr.io/${var.project_id}/coffee-pun-backend"
    }
  }

  depends_on = [
    google_project_service.cloudrun,
    google_project_iam_member.cloudbuild_artifact_writer
  ]
}

resource "google_cloud_run_v2_service" "frontend" {
  name     = "coffee-pun-frontend-tf"
  location = var.region

  template {
    containers {
      image = "gcr.io/${var.project_id}/coffee-pun-frontend"
      ports {
        container_port = 8080
      }
    }
  }

  depends_on = [
    google_project_service.cloudrun,
    google_project_iam_member.cloudbuild_artifact_writer
  ]
}

resource "google_cloud_run_service_iam_binding" "backend_noauth" {
  location = google_cloud_run_v2_service.backend.location
  service  = google_cloud_run_v2_service.backend.name
  role     = "roles/run.invoker"
  members = [
    "allUsers",
  ]
}

resource "google_cloud_run_service_iam_binding" "frontend_noauth" {
  location = google_cloud_run_v2_service.frontend.location
  service  = google_cloud_run_v2_service.frontend.name
  role     = "roles/run.invoker"
  members = [
    "allUsers",
  ]
}
