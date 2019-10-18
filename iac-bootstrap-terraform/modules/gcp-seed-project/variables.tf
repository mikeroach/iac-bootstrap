variable gcp_organization_id {
  type        = string
  description = "ID of the Google Cloud Platform organization hosting our Project Factory seed project"
}

variable gcp_billing_account {
  type        = string
  description = "ID of the Google Cloud Platform billing account associated with our Project Factory seed project"
}

variable "gcp_seed_project" {
  type        = string
  description = "Base ID of the GCP Seed Project per https://github.com/terraform-google-modules/terraform-google-project-factory/blob/v3.2.0/docs/GLOSSARY.md"
}

variable "gcp_seed_sa_credentials" {
  type        = string
  description = "File path to GCP seed service account credentials. Moved to defined location after creation within this module"
}

variable "gcp_seed_sa_email" {
  type        = string
  description = "File path to GCP seed service account email. Extracted from JSON credentials created within this module"
}

variable "gcp_seed_sa_id" {
  type        = string
  description = "File path to GCP seed service account ID. Extracted from JSON credentials created within this module"
}

variable "gcp_seed_sa_privkey" {
  type        = string
  description = "File path to GCP seed service account SSH private key. Extracted from JSON credentials created within this module"
}

variable "gcp_seed_sa_pubkey" {
  type        = string
  description = "File path to GCP seed service account SSH public key. Generated from SSH private key extracted within this module"
}

variable project_factory_version {
  type        = string
  description = "Version of the Google Cloud Project Factory Terraform Module specified in our IaC Bootstrap module root"
}

variable seed_project_services {
  type        = list(string)
  description = "Authoritative list of enabled API services for the GCP Seed Project (please verify this includes services enabled by GPF module helper script!)"
}

variable seed_project_tfstate_acl {
  type        = list(string)
  description = "Inline list of role/entity pairs to apply as ACL for GCS bucket hosting Terraform remote state. See https://www.terraform.io/docs/providers/google/r/storage_bucket_acl.html for syntax"
}

variable seed_project_tfstate_bucket {
  type        = string
  description = "Globally unique name for the GCS bucket hosting Terraform remote state files"
}