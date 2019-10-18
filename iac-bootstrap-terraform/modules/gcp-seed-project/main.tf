/* This module creates a GCP seed project which will host a seed service account
used by the GCP Project Factory Terraform Module to provision other projects.

Also use this seed account to host at least one GCS bucket for storing Terraform
remote state. For simplicity's sake I'll start by putting all remote states in one
bucket and managing per-object access with ACLs, though as I gain more Terraform
experience and my hypothetical demo organizational structure evolves I should
consider when/if it makes sense to segregate into per-"team"/environment/project
buckets.

See:
https://github.com/terraform-google-modules/terraform-google-project-factory
https://cloud.google.com/community/tutorials/managing-gcp-projects-with-terraform */

/* I haven't yet decided how I want to organize GCP folders in my one-person
 organization (by application, "team", environment?) yet, but I'll explicitly create
 a root folder and place everything there to avoid triggering this Terraform issue:
https://github.com/terraform-providers/terraform-provider-google/issues/1701 */

resource "google_folder" "root" {
  display_name = "Root Folder"
  parent       = "organizations/${var.gcp_organization_id}"
}

/* Generate a random project ID suffix to ensure global uniqueness per:
https://cloud.google.com/resource-manager/docs/creating-managing-projects
https://www.terraform.io/docs/providers/random/r/id.html */

resource "random_id" "project_id_suffix" {
  byte_length = 3
  keepers = {
    project_id_prefix = "${var.gcp_seed_project}"
  }
}

resource "google_project" "seed_project" {
  name            = "IaC Admin Seed Project"
  billing_account = var.gcp_billing_account
  folder_id       = google_folder.root.name
  project_id      = "${var.gcp_seed_project}-${random_id.project_id_suffix.hex}"

  /* Run the current GCP Project Factory version's module service account helper script
  and move its generated credentials to the encrypted secrets directory, then extract the
  SSH keypair and account ID details from GCP credentials JSON and use them to create an
  OS Login profile for instance provisioning. In retrospect it may be simpler to just
  implement the helper script functionality in Terraform. */
  provisioner "local-exec" {
    command = <<EOF
    `jq -r < .terraform/modules/modules.json '.Modules[] | select(.Key=="management-project" and .Version=="${var.project_factory_version}") | .Dir'`/helpers/setup-sa.sh ${var.gcp_organization_id} ${self.project_id} ${var.gcp_billing_account}
    mv credentials.json "${var.gcp_seed_sa_credentials}"
    jq -r .private_key < "${var.gcp_seed_sa_credentials}" > "${var.gcp_seed_sa_privkey}"
    chmod 600 "${var.gcp_seed_sa_privkey}"
    ssh-keygen -y -f "${var.gcp_seed_sa_privkey}" > "${var.gcp_seed_sa_pubkey}"
    jq -j .client_email < "${var.gcp_seed_sa_credentials}" > "${var.gcp_seed_sa_email}"
    jq -j .client_id < "${var.gcp_seed_sa_credentials}" > "${var.gcp_seed_sa_id}"
    gcloud auth activate-service-account --key-file="${var.gcp_seed_sa_credentials}"
    gcloud compute os-login ssh-keys add --key-file="${var.gcp_seed_sa_pubkey} --ttl 0
    EOF
  }
}

// Set a lien on the Seed Project so we don't accidentally delete it.
resource "google_resource_manager_lien" "seed_project_lien" {
  parent       = "projects/${google_project.seed_project.number}"
  origin       = "Terraform"
  reason       = "This project hosts our IaC bootstrap environment and Terraform state backend for all other environments."
  restrictions = ["resourcemanager.projects.delete"]
}

// Remember to verify all services enabled here include those needed by the Project Factory module!
/* FIXME: This is going to break with version 3 of the Terraform GCP provider. See:
https://www.terraform.io/docs/providers/google/version_3_upgrade.html#resource-google_project_services */
resource "google_project_services" "seed_project" {
  project  = "${google_project.seed_project.project_id}"
  services = var.seed_project_services
}

// Create a GCS bucket backend for storing Terraform state as described above...
resource "google_storage_bucket" "terraform_state" {
  name               = var.seed_project_tfstate_bucket
  bucket_policy_only = false
  location           = "US"
  project            = "${google_project.seed_project.project_id}"
  versioning {
    enabled = true
  }
}

// ... and apply an appropriate access control list since this will contain sensitive data.
resource "google_storage_bucket_acl" "terraform_state_acl" {
  bucket      = "${google_storage_bucket.terraform_state.name}"
  role_entity = var.seed_project_tfstate_acl
}
