provider "google" {
  credentials = file("CREDENTIALS.json")
  project     = var.project_id
  region      = var.region
}

resource "google_project_service" "vision-api" {
  project                    = var.project_id
  service                    = "vision.googleapis.com"
  disable_dependent_services = true
}

resource "google_project_service" "firestore-api" {
  project                    = var.project_id
  service                    = "firestore.googleapis.com"
  disable_dependent_services = true
}

resource "google_project_service" "appengine-api" {
  project                    = var.project_id
  service                    = "appengine.googleapis.com"
  disable_dependent_services = true
}

resource "google_project_service" "cloudfunctions-api" {
  project                    = var.project_id
  service                    = "cloudfunctions.googleapis.com"
  disable_dependent_services = true
}

resource "google_project_service" "cloudbuild-api" {
  project                    = var.project_id
  service                    = "cloudbuild.googleapis.com"
  disable_dependent_services = true
}

resource "google_project_service" "cloudrun-api" {
  project                    = var.project_id
  service                    = "run.googleapis.com"
  disable_dependent_services = true
}

resource "google_project_service" "container-api" {
  project                    = var.project_id
  service                    = "containerregistry.googleapis.com"
  disable_dependent_services = true
}

resource "google_project_service" "pubsub-api" {
  project                    = var.project_id
  service                    = "pubsub.googleapis.com"
  disable_dependent_services = true
}

resource "google_project_service" "iam-api" {
  project                    = var.project_id
  service                    = "iam.googleapis.com"
  disable_dependent_services = true
}

resource "google_project_service" "schedule-api" {
  project                    = var.project_id
  service                    = "cloudscheduler.googleapis.com"
  disable_dependent_services = true
}
