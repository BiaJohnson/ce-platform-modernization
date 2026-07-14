variable "project_id" {
  description = "GCP project ID (immutable string, e.g. your-gcp-project-id)"
  type        = string
}

variable "region" {
  description = "Region for Cloud Run and Artifact Registry (us-central1 is free-tier friendly)"
  type        = string
  default     = "us-central1"
}

variable "artifact_registry_repo" {
  description = "Artifact Registry Docker repository ID"
  type        = string
  default     = "platform"
}

variable "image_tag" {
  description = "Container image tag for both services (must already exist in Artifact Registry)"
  type        = string
  default     = "v1"
}

variable "allow_unauthenticated_public" {
  description = <<-EOT
    If true, grant roles/run.invoker to allUsers on the public Cloud Run service
    so workshop attendees can hit the HTTPS URL without a token.
    Internal service stays authenticated-only either way.
  EOT
  type        = bool
  default     = true
}

variable "enable_load_balancer" {
  description = "Reserved for a future Global HTTPS LB + Cloud Armor path. Unused in this PoC."
  type        = bool
  default     = false
}

# Referenced so the reserved flag is part of the config graph without deploying an LB.
locals {
  load_balancer_reserved = var.enable_load_balancer
}
