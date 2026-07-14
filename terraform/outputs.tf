output "public_url" {
  description = "HTTPS URL for the public Cloud Run service"
  value       = google_cloud_run_v2_service.public.uri
}

output "internal_uri" {
  description = "URI of the internal Cloud Run service (identity-token audience; not reachable from the public internet)"
  value       = google_cloud_run_v2_service.internal.uri
}

output "public_service_account_email" {
  description = "Runtime SA for public-api (holds run.invoker on internal-api)"
  value       = google_service_account.public_api.email
}

output "internal_service_account_email" {
  description = "Runtime SA for internal-api"
  value       = google_service_account.internal_api.email
}

output "artifact_registry_repository" {
  description = "Artifact Registry Docker repo hosting the images"
  value       = google_artifact_registry_repository.platform.name
}

output "destroy_reminder" {
  description = "Cost habit: destroy idle Cloud Run when you are done demos for the day"
  value       = "When idle: cd terraform && terraform destroy. Images in Artifact Registry can stay (cheap) or be deleted separately."
}
