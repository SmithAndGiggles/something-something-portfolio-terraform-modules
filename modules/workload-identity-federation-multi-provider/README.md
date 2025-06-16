# GCP Workload Identity Federation Multi Provider Module

This module allows you to create a Workload Identity Pool, multiple providers (OIDC, AWS, SAML), and service accounts with IAM bindings for federated access.

## Roles Needed
- roles/iam.workloadIdentityPoolAdmin
- roles/iam.serviceAccountAdmin

## Enable APIs
- cloudresourcemanager.googleapis.com
- iam.googleapis.com
- iamcredentials.googleapis.com
- sts.googleapis.com

## Sample Usage

```hcl
module "wif" {
  source     = "./modules/workload-identity-federation-multi-provider"

  project_id = "my-project"
  pool_id    = "my-pool"
  wif_providers = [
    {
      provider_id          = "my-provider-1"
      select_provider      = "oidc"
      provider_config      = {
        issuer_uri = "https://token.actions.githubusercontent.com"
        allowed_audiences = "https://example.com/gcp-oidc-federation,example.com/gcp-oidc-federation"
      }
      disabled             = false
      attribute_condition  = "\"e968c2ef-047c-498d-8d79-16ca1b61e77e\" in assertion.groups"
      attribute_mapping    = {
        "attribute.actor"      = "assertion.actor"
        "attribute.repository" = "assertion.repository"
        "google.subject"       = "assertion.sub"
      }
    },
    {
      provider_id          = "my-provider-2"
      select_provider      = "aws"
      provider_config      = {
        account_id = "999999999999"
      }
      disabled             = false
      attribute_condition  = "attribute.aws_role==\"arn:aws:sts::999999999999:assumed-role/stack-eu-central-1-lambdaRole\""
      attribute_mapping    = {
        "attribute.actor" = "assertion.actor"
        "google.subject"  = "assertion.sub"
      }
    }
  ]
  service_accounts = [
    {
      name           = "wif-sa-1"
      attribute      = "attribute.repository/my-org/my-repo"
      all_identities = true
      roles          = ["roles/compute.admin"]
    }
  ]
}
```

## Inputs
- `project_id`: The GCP project ID.
- `pool_id`: The Workload Identity Pool ID.
- `wif_providers`: List of provider configs (see example above).
- `service_accounts`: List of service accounts and their IAM bindings.

---

See the `main.tf` for full variable and resource details.
