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
