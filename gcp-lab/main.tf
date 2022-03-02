// Configure the Google Cloud Provider
// terraform import google_app_engine_application.firestore terraform-playaround
provider "google" {
  credentials = file("CREDENTIALS.json")
  project     = var.project_id
  region      = var.region
}
