output "ruta_registro" {
  value = "${var.region}-docker.pkg.dev/${var.proyecto}/${google_artifact_registry_repository.imagenes.repository_id}"
}

output "url_backend" {
  value = google_cloud_run_v2_service.backend.uri
}