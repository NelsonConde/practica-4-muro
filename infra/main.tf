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

# Servicio de Cloud Run que ejecuta la imagen Docker del backend.
resource "google_cloud_run_v2_service" "backend" {
  name                = "${var.prefijo}-backend"
  location            = var.region
  # Permite eliminar el servicio mediante terraform destroy.
  deletion_protection = false
  # El servicio se crea después de habilitar las APIs requeridas.
  depends_on = [google_project_service.apis]

  template {
    # Identidad utilizada por el backend para acceder a servicios de Google Cloud.
    # Sepodria de forma predeterminada pero se hace porque el que creamos si tiene permisos para firestore
    service_account = google_service_account.backend.email

    containers {
      # Imagen Docker del backend almacenada en Artifact Registry.
      image = var.imagen_backend

      env {
        # Nombre de la variable que utiliza la aplicación para identificar Firestore.
        name = "BASE_DATOS"
        # Obtiene automáticamente el nombre de la base Firestore creada por Terraform.
        value = google_firestore_database.db.name
      }
    }

    scaling {
      # Limita el servicio a un máximo de tres instancias.
      max_instance_count = 3
    }
  }
}

# Permite que el backend pueda ser invocado públicamente por Internet.
resource "google_cloud_run_v2_service_iam_member" "backend_publico" {

  # Aplica el permiso al servicio Cloud Run creado anteriormente.
  name     = google_cloud_run_v2_service.backend.name
  location = google_cloud_run_v2_service.backend.location

  # Permiso requerido para invocar un servicio de Cloud Run.
  role = "roles/run.invoker"

  # Permite el acceso a cualquier usuario de Internet.
  member = "allUsers"
}

# Ahora para el frontend

resource "google_service_account" "frontend" {
  account_id   = "${var.prefijo}-frontend"
  display_name = "Frontend del muro"
  depends_on   = [google_project_service.apis]
}

resource "google_cloud_run_v2_service" "frontend" {
  name                = "${var.prefijo}-frontend"
  location            = var.region
  deletion_protection = false
  depends_on = [google_project_service.apis]

  template {
    service_account = google_service_account.frontend.email

    containers {
      image = var.imagen_frontend
      env {
        name = "BACKEND_URL"
        value = google_cloud_run_v2_service.backend.uri
      }
    }
    scaling {
      max_instance_count = 2
    }

  }
}

resource "google_cloud_run_v2_service_iam_member" "frontend_publico" {

  name     = google_cloud_run_v2_service.frontend.name
  location = google_cloud_run_v2_service.frontend.location

  role = "roles/run.invoker"

  member = "allUsers"
}