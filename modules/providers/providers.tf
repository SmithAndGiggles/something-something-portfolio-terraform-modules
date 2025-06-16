# ------------------------------------------------------------------------------
# Terraform Backend & Provider
# ------------------------------------------------------------------------------

terraform {

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.38.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "6.38.0"
    }
  }
}

