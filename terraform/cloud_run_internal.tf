locals {
  internal_image = "${var.region}-docker.pkg.dev/${var.project_id}/${var.artifact_registry_repo}/internal-api:${var.image_tag}"
}

# Private tier: no public internet. Reachable only from within the project/VPC
# (and Cloud Run→Cloud Run) with a valid identity token + run.invoker.

resource "google_cloud_run_v2_service" "internal" {
  name     = "internal-api"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_INTERNAL_ONLY"

  template {
    service_account = google_service_account.internal_api.email

    scaling {
      min_instance_count = 0
      max_instance_count = 3
    }

    containers {
      image = local.internal_image

      ports {
        container_port = 8080
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
    }
  }

  depends_on = [
    google_project_service.apis,
    google_artifact_registry_repository.platform,
  ]
}

# Public SA may invoke this service (identity-token audience = this URI).
# No allUsers — that is the networking/security talking point for the workshop.

resource "google_cloud_run_v2_service_iam_member" "internal_invoker_public_sa" {
  project  = var.project_id
  location = google_cloud_run_v2_service.internal.location
  name     = google_cloud_run_v2_service.internal.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.public_api.email}"
}
