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
