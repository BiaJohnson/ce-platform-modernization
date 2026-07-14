# Direct VPC egress for public→internal Cloud Run calls.
# With ingress=INTERNAL_ONLY, peer Cloud Run traffic only counts as internal
# when it arrives via a VPC (default Cloud Run egress goes out to the internet
# and is blocked with a Google Front End 404).
#
# Pattern: Direct VPC egress (private-ranges-only) + Private Google Access +
# private DNS for run.app → private.googleapis.com VIP range.
# See: https://cloud.google.com/run/docs/securing/private-networking#from-other-services

locals {
  # private.googleapis.com VIP range (Private Google Access)
  private_googleapis_vips = [
    "199.36.153.8",
    "199.36.153.9",
    "199.36.153.10",
    "199.36.153.11",
  ]
}

resource "google_compute_network" "poc" {
  name                    = "platform-poc"
  auto_create_subnetworks = false
  description             = "PoC VPC so public-api egress is recognized as internal"

  depends_on = [google_project_service.apis]
}

resource "google_compute_subnetwork" "poc" {
  name                     = "platform-poc"
  ip_cidr_range            = "10.8.0.0/24"
  region                   = var.region
  network                  = google_compute_network.poc.id
  private_ip_google_access = true
  description              = "Subnet for Cloud Run Direct VPC egress (Private Google Access on)"
}

# Resolve *.run.app to the private.googleapis.com VIP so traffic stays on the VPC
# (private-ranges-only) and is classified as internal at the destination service.
resource "google_dns_managed_zone" "run_app" {
  name        = "run-app-private"
  dns_name    = "run.app."
  description = "Private DNS so Cloud Run URLs resolve via Private Google Access"
  visibility  = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.poc.id
    }
  }

  depends_on = [google_project_service.apis]
}

resource "google_dns_record_set" "run_app_a" {
  name         = "run.app."
  managed_zone = google_dns_managed_zone.run_app.name
  type         = "A"
  ttl          = 300
  rrdatas      = local.private_googleapis_vips
}

# Single-label hosts under run.app (e.g. example.run.app)
resource "google_dns_record_set" "run_app_wildcard" {
  name         = "*.run.app."
  managed_zone = google_dns_managed_zone.run_app.name
  type         = "A"
  ttl          = 300
  rrdatas      = local.private_googleapis_vips
}

# Legacy Cloud Run URLs: https://SERVICE-xxxxx-uc.a.run.app
resource "google_dns_record_set" "run_app_a_run_wildcard" {
  name         = "*.a.run.app."
  managed_zone = google_dns_managed_zone.run_app.name
  type         = "A"
  ttl          = 300
  rrdatas      = local.private_googleapis_vips
}

# Regional Cloud Run URLs: https://SERVICE-PROJECTNUM.us-central1.run.app
resource "google_dns_record_set" "run_app_region_wildcard" {
  name         = "*.${var.region}.run.app."
  managed_zone = google_dns_managed_zone.run_app.name
  type         = "A"
  ttl          = 300
  rrdatas      = local.private_googleapis_vips
}
