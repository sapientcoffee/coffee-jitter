variable "project_id" {
  description = "The Google Cloud project ID."
  type        = string
}

variable "region" {
  description = "The Google Cloud region to deploy to."
  type        = string
  default     = "us-central1"
}

variable "cloudbuild_service_account" {
  description = "The service account for Cloud Build."
  type        = string
}
