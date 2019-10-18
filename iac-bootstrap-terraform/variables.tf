variable "bootstrap_salt_repo" {
  type        = string
  description = "File path to local IaC bootstrap Salt combined state+pillar repository. Omit trailing slash"
}

variable "docker_client_cert" {
  type        = string
  description = "File path to client certificate used by Docker provider for TLS connection to Docker host"
}

variable "docker_client_key" {
  type        = string
  description = "File path to client private key used by Docker provider for TLS connection to Docker host"
}

variable "docker_jenkins_envvars" {
  type        = list(string)
  description = "Environment variables that will be injected into the Jenkins container at runtime. Watch out! Anyone who has access to inspect the running Docker container can see secret credentials supplied this way"
}

variable "docker_jenkins_image" {
  type        = string
  description = "Registry path to Jenkins container image"
  default     = "$dockerhub_username/$image_name:$tag"
}

variable "docker_volume_size" {
  type        = string
  description = "Size in GB of the persistent disk to create and attach to our IaC management server for storing Docker volumes"
}

variable "gcp_admin_credentials" {
  type        = string
  description = "File path to the GCP admin account credentials. Requires permissions defined at: https://github.com/terraform-google-modules/terraform-google-project-factory/blob/v3.2.0/README.md#permissions"
}

variable gcp_billing_account {
  type        = string
  description = "ID of the Google Cloud Platform billing account associated with our Project Factory seed project"
}

variable gcp_organization_id {
  type        = string
  description = "ID of the Google Cloud Platform organization hosting our Project Factory seed project"
}

variable "gcp_region" {
  type        = string
  description = "Google Cloud Platform region to house our IaC management environment"
}

variable "gcp_zone" {
  type        = string
  description = "Google Cloud Platform compute zone to launch our IaC management servers"
}

variable "gcp_seed_sa_credentials" {
  type        = string
  description = "File path to GCP seed service account credentials. Created by the gcp-seed-project module"
  default     = "../secrets/project-factory-seed-service-account.json"
}

variable "gcp_seed_sa_email" {
  type        = string
  description = "File path to GCP seed service account email. Created by the gcp-seed-project module"
  default     = "../secrets/project-factory-seed-service-account.email"
}

variable "gcp_seed_sa_id" {
  type        = string
  description = "File path to GCP seed service account userid. Created by the gcp-seed-project module"
  default     = "../secrets/project-factory-seed-service-account.id"
}

variable "gcp_seed_sa_privkey" {
  type        = string
  description = "File path to GCP seed service account SSH private key. Created by the gcp-seed-project module"
  default     = "../secrets/project-factory-seed-service-account.key"
}

variable "gcp_seed_sa_pubkey" {
  type        = string
  description = "File path to GCP seed service account SSH public key. Created by the gcp-seed-project module"
  default     = "../secrets/project-factory-seed-service-account.pub"
}

variable "gcp_seed_project" {
  type        = string
  description = "Base ID of the GCP Seed Project per https://github.com/terraform-google-modules/terraform-google-project-factory/blob/v3.2.0/docs/GLOSSARY.md"
}

variable "machine_name" {
  type        = string
  description = "Name of our single IaC management server"
}

variable "machine_type" {
  type        = string
  description = "Google Cloud Platform machine type for our IaC management servers per https://cloud.google.com/compute/docs/machine-types"
}

variable "management_project" {
  type        = string
  description = "ID for the management project to create via Google Project Factory module"
}

variable "preemptible" {
  type        = bool
  description = "Define whether our IaC management server will run as preemptible (less compute-hour cost at the expense of availability)"
}

variable "project_services" {
  type        = list(string)
  description = "Authoritative list of enabled API services for environment projects"
}

variable "seed_project_services" {
  type        = list(string)
  description = "Authoritative list of enabled API services for the GCP Seed Project (please verify this includes services enabled by GPF module helper script!)"
}

variable "seed_project_tfstate_acl" {
  type        = list(string)
  description = "Inline list of role/entity pairs to apply as ACL for GCS bucket hosting Terraform remote state. See https://www.terraform.io/docs/providers/google/r/storage_bucket_acl.html for syntax"
}

variable "seed_project_tfstate_bucket" {
  type        = string
  description = "Globally unique name for the GCS bucket hosting Terraform remote state files"
}

variable "trusted_networks" {
  type        = set(string)
  description = "CIDR of trusted source networks from which to allow all management traffic"
}