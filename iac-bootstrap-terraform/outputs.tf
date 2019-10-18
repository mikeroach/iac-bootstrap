output "admin1_external_ip" {
  description = "External ephemeral IP address of the provisioned management server"
  value       = module.admin1.external_ip
}

output "project_ids" {
  description = "Map containing generated IDs of all GCP projects managed by this module (used by IaC stack template and derivative environments)"
  value = {
    "auto"  = module.auto-project.project_id
    "gated" = module.gated-project.project_id
    "mgmt1" = module.management-project.project_id
    "seed"  = module.gcp-seed-project.seed_project_id
    "tfdev" = module.tfdev-project.project_id
  }
}

output "tfstate_bucket" {
  description = "GCS bucket created to store remote Terraform state"
  value       = module.gcp-seed-project.tfstate_bucket
}