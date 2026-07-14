# GCP requires APIs to be enabled before most resources can be created
# (unlike many AWS services that "just work").

locals {
  required_apis = toset([
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "iam.googleapis.com",
    "logging.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com", # VPC + Direct VPC egress for internal Cloud Run calls
    "dns.googleapis.com",     # Private DNS for *.run.app → private.googleapis.com
  ])
}

resource "google_project_service" "apis" {
  for_each = local.required_apis

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}
