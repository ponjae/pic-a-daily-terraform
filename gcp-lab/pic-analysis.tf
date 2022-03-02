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
