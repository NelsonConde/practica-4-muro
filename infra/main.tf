resource "google_project_service" "apis" {
  for_each = toset([
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "iam.googleapis.com",
    "firestore.googleapis.com",
  ])
  service            = each.value
  disable_on_destroy = false
}

resource "google_artifact_registry_repository" "imagenes" {
  repository_id = "${var.prefijo}-imagenes"
  location      = var.region
  format        = "DOCKER"
  depends_on    = [google_project_service.apis]
}

resource "google_firestore_database" "db" {
  name            = "${var.prefijo}-db"
  location_id     = var.region
  type            = "FIRESTORE_NATIVE"
  deletion_policy = "DELETE"    # sin esto, destroy deja la base viva
  depends_on      = [google_project_service.apis]
}

resource "google_service_account" "backend" {
  account_id   = "${var.prefijo}-backend"
  display_name = "Backend del muro"
  depends_on   = [google_project_service.apis]
}

resource "google_project_iam_member" "backend_firestore" {
  project = var.proyecto
  role    = "roles/datastore.user"
  member  = "serviceAccount:${google_service_account.backend.email}"
}