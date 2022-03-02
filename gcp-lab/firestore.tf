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
