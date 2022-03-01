// Configure the Google Cloud Provider
// terraform import google_app_engine_application.firestore terraform-playaround
provider "google" {
  credentials = file("CREDENTIALS.json")
  project     = var.project_id
  region      = var.region
}

resource "google_storage_bucket_iam_member" "member" {
  bucket = google_storage_bucket.terraform-resource-bucket.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

resource "google_storage_bucket" "terraform-resource-bucket" {
  name                        = "uploaded-pictures-${var.project_id}"
  location                    = "EU"
  force_destroy               = true
  uniform_bucket_level_access = true
}

# Stage 7 - create a bucket containing a zip-file for the code in cloud functions

resource "google_storage_bucket" "code-bucket" {
  name          = "code-bucket-${var.project_id}"
  force_destroy = true
  location      = "EU"
}

resource "google_storage_bucket_object" "code-archive" {
  name   = "function.zip"
  bucket = google_storage_bucket.code-bucket.name
  source = "./code/function.zip"
}

resource "google_cloudfunctions_function" "pic-upload-function" {
  name        = "pic-upload-function"
  description = "Analyzes the uploaded picture"
  runtime     = "nodejs14"

  available_memory_mb   = 256
  source_archive_bucket = google_storage_bucket.code-bucket.name
  source_archive_object = google_storage_bucket_object.code-archive.name

  event_trigger {
    event_type = "google.storage.object.finalize"
    resource   = google_storage_bucket.terraform-resource-bucket.name
  }

  entry_point = "vision_analysis"
}

# 9. Prepare the database

# Create an appengine application in order to provision an firestore db
resource "google_app_engine_application" "firestore" {
  project       = var.project_id
  location_id   = "europe-west"
  database_type = "CLOUD_FIRESTORE"
}

resource "google_firestore_index" "my-index" {
  project = var.project_id

  collection = "pictures"

  fields {
    field_path = "thumbnail"
    order      = "DESCENDING"
  }

  fields {
    field_path = "created"
    order      = "DESCENDING"
  }
}

resource "google_firestore_document" "firestore_doc" {
  project     = var.project_id
  collection  = "pictures"
  document_id = "firestore-doc"
  fields      = ""
}

# LAB 2

resource "google_storage_bucket" "thumbnail-bucket" {
  name                        = "thumbnails-${var.project_id}"
  location                    = "EU"
  force_destroy               = true
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_iam_member" "thumb-member" {
  bucket = google_storage_bucket.thumbnail-bucket.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# 8 do it in cloud console

# 9 Deploy to cloud run

resource "google_cloud_run_service" "thumbnail-cloudrun" {
  name     = "thumbnail-service"
  location = "europe-west3"

  template {
    spec {
      containers {
        image = "gcr.io/terraform-playaround/thumbnail-service"

        env {
          name  = "BUCKET_THUMBNAILS"
          value = "thumbnails-${var.project_id}"
        }
      }
    }
  }
  traffic {
    percent         = 100
    latest_revision = true
  }
}

# 10 Cloud storage events

resource "google_pubsub_topic" "thumb-topic" {
  name = "cloudstorage-cloudrun-topic"
}

# resource "google_pubsub_topic_iam_member" "policy" {
#   topic   = google_pubsub_topic.thumb-topic.name
#   project = var.project_id
#   role    = "roles/editor"
#   member  = "serviceAccount:597544288412-compute@developer.gserviceaccount.com"
# }

data "google_storage_project_service_account" "gcs_account" {
}

resource "google_pubsub_topic_iam_binding" "topic-iam" {
  project = var.project_id
  topic   = google_pubsub_topic.thumb-topic.name
  role    = "roles/pubsub.publisher"
  members = ["serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"]
}

resource "google_storage_notification" "notification" {
  bucket         = google_storage_bucket.terraform-resource-bucket.name
  payload_format = "JSON_API_V1"
  topic          = google_pubsub_topic.thumb-topic.id
  event_types    = ["OBJECT_FINALIZE"]
  depends_on     = [google_pubsub_topic_iam_binding.topic-iam]
}

resource "google_service_account" "pubsub-sa" {
  account_id   = "${google_pubsub_topic.thumb-topic.name}-sa"
  display_name = "Cloud Run Pub/Sub Invoker"
}

data "google_iam_policy" "pubsub-sacc" {
  binding {
    role = "roles/run.invoker"

    members = [
      "serviceAccount:${google_service_account.pubsub-sa.account_id}@${var.project_id}.iam.gserviceaccount.com"
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "data-policy" {
  location    = google_cloud_run_service.thumbnail-cloudrun.location
  project     = google_cloud_run_service.thumbnail-cloudrun.project
  service     = google_cloud_run_service.thumbnail-cloudrun.name
  policy_data = data.google_iam_policy.pubsub-sacc.policy_data
}

resource "google_pubsub_subscription" "thumb-topic-subscription" {
  name  = "${google_pubsub_topic.thumb-topic.name}.subscription"
  topic = google_pubsub_topic.thumb-topic.name

  push_config {
    push_endpoint = "https://thumbnail-service-kkojdxidwq-ey.a.run.app"
    oidc_token {
      service_account_email = "${google_service_account.pubsub-sa.account_id}@${var.project_id}.iam.gserviceaccount.com"
    }
  }
}

resource "google_pubsub_subscription_iam_member" "pubsub-sub" {
  subscription = google_pubsub_subscription.thumb-topic-subscription.name
  role         = "roles/editor"
  member       = "serviceAccount:${google_service_account.pubsub-sa.account_id}@${var.project_id}.iam.gserviceaccount.com"
}



