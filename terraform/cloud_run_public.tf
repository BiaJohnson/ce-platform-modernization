locals {
  public_image = "${var.region}-docker.pkg.dev/${var.project_id}/${var.artifact_registry_repo}/public-api:${var.image_tag}"
}

# Edge tier: public HTTPS *.run.app URL. Calls internal-api with an identity token.

resource "google_cloud_run_v2_service" "public" {
  name     = "public-api"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.public_api.email

    # Route *.run.app calls into the PoC VPC (private VIP via Cloud DNS) so
    # internal-api ingress (INTERNAL_ONLY) accepts them as internal traffic.
    vpc_access {
      egress = "PRIVATE_RANGES_ONLY"

      network_interfaces {
        network    = google_compute_network.poc.id
        subnetwork = google_compute_subnetwork.poc.id
      }
    }

    scaling {
      min_instance_count = 0
      max_instance_count = 3
    }

    containers {
      image = local.public_image

      env {
        name  = "INTERNAL_SERVICE_URL"
        value = google_cloud_run_v2_service.internal.uri
      }

      env {
        name  = "GCP_PROJECT"
        value = var.project_id
      }

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
    google_cloud_run_v2_service_iam_member.internal_invoker_public_sa,
    google_compute_subnetwork.poc,
    google_dns_record_set.run_app_a,
    google_dns_record_set.run_app_wildcard,
    google_dns_record_set.run_app_a_run_wildcard,
    google_dns_record_set.run_app_region_wildcard,
  ]
}

# Workshop default: unauthenticated invoke on the *public* service only.
# Set allow_unauthenticated_public = false to require a caller identity token instead.

resource "google_cloud_run_v2_service_iam_member" "public_invoker_all_users" {
  count = var.allow_unauthenticated_public ? 1 : 0

  project  = var.project_id
  location = google_cloud_run_v2_service.public.location
  name     = google_cloud_run_v2_service.public.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
