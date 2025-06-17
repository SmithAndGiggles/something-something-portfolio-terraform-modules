variable "project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "pool_id" {
  description = "The Workload Identity Pool ID."
  type        = string
}

variable "provider_id" {
  description = "The Workload Identity Pool Provider ID."
  type        = string
}

variable "display_name" {
  description = "Display name for the pool and provider."
  type        = string
  default     = null
}

variable "description" {
  description = "Description for the pool and provider."
  type        = string
  default     = null
}

variable "service_account_email" {
  description = "The email of the service account to grant roles to."
  type        = string
}

variable "project_roles" {
  description = "List of project roles to grant to the service account."
  type        = list(string)
  default     = []
}

variable "attribute" {
  description = "The attribute to use for the principalSet member (e.g., 'subject' or 'repository')."
  type        = string
  default     = "subject"
}

resource "google_iam_workload_identity_pool" "this" {
  provider                  = google-beta
  project                   = var.project_id
  workload_identity_pool_id = var.pool_id
  display_name              = var.display_name
  description               = var.description
}

resource "google_iam_workload_identity_pool_provider" "this" {
  provider                          = google-beta
  project                           = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.this.workload_identity_pool_id
  workload_identity_pool_provider_id = var.provider_id
  display_name                      = var.display_name
  description                       = var.description
  attribute_mapping = {
    "google.subject"        = "assertion.sub"
    "attribute.repository"  = "assertion.repository"
  }
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

module "member_roles" {
  source   = "terraform-google-modules/iam/google//modules/member_iam"
  version  = "~> 8.0"

  service_account_address = var.service_account_email
  prefix                  = "serviceAccount"
  project_id              = var.project_id
  project_roles           = var.project_roles
}
