resource "google_pubsub_topic" "thumb-topic" {
  name = "cloudstorage-cloudrun-topic"
}

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
    push_endpoint = google_cloud_run_service.thumbnail-cloudrun.status[0].url
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
