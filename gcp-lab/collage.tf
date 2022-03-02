resource "google_cloud_run_service" "collage-cloudrun" {
  name     = "collage-service"
  location = "europe-west3"

  template {
    spec {
      containers {
        image = "gcr.io/terraform-playaround/collage-service"

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

# 8. Set up Cloud Scheduler

resource "google_service_account" "collage-sa" {
  account_id   = "collage-scheduler-sa"
  display_name = "Collage Scheduler Service Account"
}



data "google_iam_policy" "collage-sacc" {
  binding {
    role = "roles/run.invoker"

    members = [
      "serviceAccount:${google_service_account.collage-sa.account_id}@${var.project_id}.iam.gserviceaccount.com"
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "collage-policy" {
  location    = google_cloud_run_service.collage-cloudrun.location
  project     = google_cloud_run_service.collage-cloudrun.project
  service     = google_cloud_run_service.collage-cloudrun.name
  policy_data = data.google_iam_policy.collage-sacc.policy_data
}

resource "google_cloud_scheduler_job" "scheduler" {
  name     = "collage-service-job"
  schedule = "0 */2 * * 1-5"

  retry_config {
    retry_count = 1
  }

  http_target {
    http_method = "GET"
    uri         = "${google_cloud_run_service.collage-cloudrun.status[0].url}/"

    oidc_token {
      service_account_email = "${google_service_account.collage-sa.account_id}@${var.project_id}.iam.gserviceaccount.com"
    }

  }
}
