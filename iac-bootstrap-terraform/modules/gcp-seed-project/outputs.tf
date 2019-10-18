output "root_folder" {
  description = "ID of our organization's root folder"
  value       = google_folder.root.name
}

output "seed_project_id" {
  description = "Generated ID of the GCP Seed Project per https://github.com/terraform-google-modules/terraform-google-project-factory/blob/v3.2.0/docs/GLOSSARY.md"
  value       = google_project.seed_project.project_id
}

output "tfstate_bucket" {
  description = "GCS bucket created to store remote Terraform state"
  value       = google_storage_bucket.terraform_state.name
}