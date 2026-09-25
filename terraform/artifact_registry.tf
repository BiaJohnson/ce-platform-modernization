# Sole owner of the Docker repository. build-and-push.sh only pushes images.
resource "google_artifact_registry_repository" "platform" {
  location      = var.region
  repository_id = var.artifact_registry_repo
  description   = "Platform modernization PoC images"
  format        = "DOCKER"

  depends_on = [google_project_service.apis]
}
