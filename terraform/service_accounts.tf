# Runtime identities for each Cloud Run service (like IAM roles for apps).

resource "google_service_account" "public_api" {
  account_id   = "sa-public-api"
  display_name = "Public API Cloud Run runtime"
  description  = "Runs public-api; needs run.invoker on internal-api"
}

resource "google_service_account" "internal_api" {
  account_id   = "sa-internal-api"
  display_name = "Internal API Cloud Run runtime"
  description  = "Runs internal-api behind IAM + internal ingress"
}
