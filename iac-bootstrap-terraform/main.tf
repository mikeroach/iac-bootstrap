/* This root module manages the submodules and resources for an Infrastructure as
Code Bootstrap build/administrative environment which gives us the ability to run
automated application and infrastructure pipelines. See ../README.md for details. */

/* Note the Docker provider configuration is located within that nested module since
its host address doesn't exist until after we run the gcp-mgmt-instance module.

Per https://www.terraform.io/docs/configuration/modules.html#providers-within-modules :
While in principle provider blocks can appear in any module, it is recommended that
they be placed only in the root module of a configuration, since this approach allows
users to configure providers just once and re-use them across all descendant modules.
See also "Passing Providers Explicitly" section of same page. */

/* FIXME: Refactor the gcp-seed-project module's project API services management before
upgrading to v3+ of the Terraform GCP provider. See here for more information:
https://www.terraform.io/docs/providers/google/version_3_upgrade.html#resource-google_project_services

Also, BOLO for issues related to bigquery-json and bigquery.googleapis.com API services with
v2.14.0 per: https://github.com/terraform-providers/terraform-provider-google/issues/4590 */

// Only used by the gcp-seed-project module.
provider "google" {
  alias       = "google-admin"
  version     = "2.15.0"
  credentials = "${file(var.gcp_admin_credentials)}"
  region      = var.gcp_region
}

// Used by the project-factory and other GCP related modules.
provider "google" {
  version     = "2.15.0"
  credentials = "${file(var.gcp_seed_sa_credentials)}"
  region      = var.gcp_region
}

// Used by the project-factory and other GCP related modules.
provider "google-beta" {
  version     = "2.15.0"
  credentials = "${file(var.gcp_seed_sa_credentials)}"
  region      = var.gcp_region
}

provider "external" {
  version = "1.2"
}

provider "null" {
  version = "2.1"
}

provider "random" {
  version = "2.1"
}

/* Uncomment this after creating the remote state GCS bucket via the gcp-seed-project
module. Configuration is defined in secrets/backend.tf so invoke TF with -backend-config
argument per https://www.terraform.io/docs/backends/config.html#partial-configuration . */
terraform {
  backend "gcs" {}
}

/* Since I want to use the Google Project Factory Terraform module to create GCP projects associated
with this infrastructure, let's create a GCP Seed Project as part of the IaC bootstrap process. */
module "gcp-seed-project" {
  source                      = "./modules/gcp-seed-project"
  providers                   = { google = "google.google-admin" }
  gcp_billing_account         = var.gcp_billing_account
  gcp_organization_id         = var.gcp_organization_id
  gcp_seed_project            = var.gcp_seed_project
  gcp_seed_sa_credentials     = var.gcp_seed_sa_credentials
  gcp_seed_sa_email           = var.gcp_seed_sa_email
  gcp_seed_sa_id              = var.gcp_seed_sa_id
  gcp_seed_sa_privkey         = var.gcp_seed_sa_privkey
  gcp_seed_sa_pubkey          = var.gcp_seed_sa_pubkey
  project_factory_version     = "${data.external.project-factory-version.result.version}"
  seed_project_services       = var.seed_project_services
  seed_project_tfstate_acl    = var.seed_project_tfstate_acl
  seed_project_tfstate_bucket = var.seed_project_tfstate_bucket
}

/* This is the least terrible way I could figure to invoke the correct Service Account helper
script during gcp-seed-project provisioning; see get-project-factory-version.sh for ugly details. */
data "external" "project-factory-version" {
  program = ["get-project-factory-version.sh"]
}

// Create a project to host our build and management infrastructure environment.
module "management-project" {
  source                  = "terraform-google-modules/project-factory/google"
  version                 = "3.2.0" // Key for get-project-factory-version.sh (don't change or remove this MAGIC comment!)
  activate_apis           = var.project_services
  apis_authority          = true
  billing_account         = var.gcp_billing_account
  credentials_path        = var.gcp_seed_sa_credentials
  default_service_account = "delete"
  folder_id               = "${module.gcp-seed-project.root_folder}"
  group_name              = "devops"
  lien                    = true
  name                    = "IaC Bootstrap - MGMT1 Env"
  org_id                  = var.gcp_organization_id
  project_id              = var.management_project
}

/* Set management project metadata to enable OS login and default instance region/zone.
It'd be great if I could do this natively via the Project Factory module. */
module "management-project-metadata" {
  source  = "./modules/gcp-project-metadata"
  project = module.management-project.project_id
  metadata = {
    enable-oslogin                = "true"
    google-compute-default-region = "${var.gcp_region}"
    google-compute-default-zone   = "${var.gcp_zone}"
  }
}

// Create shared VPC in the management environment project.
module "shared-vpc" {
  source                                 = "terraform-google-modules/network/google"
  version                                = "1.1.0"
  project_id                             = module.management-project.project_id
  network_name                           = "shared-vpc"
  shared_vpc_host                        = true
  routing_mode                           = "REGIONAL"
  delete_default_internet_gateway_routes = true // I prefer to create my own default route, thank you very much.

  subnets = [
    {
      subnet_name           = "mgmt1-${var.gcp_region}"
      subnet_ip             = "10.0.0.0/24"
      subnet_region         = var.gcp_region
      subnet_private_access = true
      subnet_flow_logs      = false
    },
  ]

  secondary_ranges = {
    "mgmt1-${var.gcp_region}" = []
  }

  routes = [
    {
      name              = "default-internet-route"
      description       = "Default route to the Internet."
      destination_range = "0.0.0.0/0"
      next_hop_internet = true
      priority          = "1000"
    }
  ]
}

// Configure firewall rules in the shared VPC network to protect our management resources.
module "management-firewall" {
  source           = "./modules/gcp-firewall"
  gcp_project      = "${module.management-project.project_id}"
  network          = "${module.shared-vpc.network_name}"
  trusted_networks = var.trusted_networks
}

// Provision compute instance to act as Docker container host in our IaC management environment.
module "admin1" {
  source              = "./modules/gcp-mgmt-instance"
  bootstrap_salt_repo = var.bootstrap_salt_repo
  docker_volume_size  = var.docker_volume_size
  gcp_project         = module.management-project.project_id
  gcp_seed_sa_id      = var.gcp_seed_sa_id
  gcp_seed_sa_privkey = var.gcp_seed_sa_privkey
  gcp_zone            = var.gcp_zone
  machine_name        = var.machine_name
  machine_type        = var.machine_type
  preemptible         = var.preemptible
  subnet              = "mgmt1-${var.gcp_region}"
}

module "docker" {
  source                 = "./modules/docker"
  docker_client_cert     = var.docker_client_cert
  docker_client_key      = var.docker_client_key
  docker_host            = "${module.admin1.external_ip}"
  docker_jenkins_image   = var.docker_jenkins_image
  docker_jenkins_envvars = var.docker_jenkins_envvars
}

// Create isolated project for Terraform development (IaC Template Pipeline runs its tests here).
module "tfdev-project" {
  source                  = "terraform-google-modules/project-factory/google"
  version                 = "3.2.0"
  activate_apis           = var.project_services
  apis_authority          = true
  billing_account         = var.gcp_billing_account
  credentials_path        = var.gcp_seed_sa_credentials
  default_service_account = "keep"
  folder_id               = "${module.gcp-seed-project.root_folder}"
  group_name              = "devops"
  lien                    = true
  name                    = "terraform-development-env"
  org_id                  = var.gcp_organization_id
  random_project_id       = true
}

/* Set project metadata to enable OS login and default instance region/zone.
It'd be great if I could do this natively via the Project Factory module. */
module "tfdev-project-project-metadata" {
  source  = "./modules/gcp-project-metadata"
  project = module.tfdev-project.project_id
  metadata = {
    enable-oslogin                = "true"
    google-compute-default-region = "${var.gcp_region}"
    google-compute-default-zone   = "${var.gcp_zone}"
  }
}

// Create target project for automatic GitOps/CD deployments.
module "auto-project" {
  source                  = "terraform-google-modules/project-factory/google"
  version                 = "3.2.0"
  activate_apis           = var.project_services
  apis_authority          = true
  billing_account         = var.gcp_billing_account
  credentials_path        = var.gcp_seed_sa_credentials
  default_service_account = "keep"
  folder_id               = "${module.gcp-seed-project.root_folder}"
  group_name              = "devops"
  lien                    = true
  name                    = "auto-promotion-env"
  org_id                  = var.gcp_organization_id
  random_project_id       = true
}

/* Set project metadata to enable OS login and default instance region/zone.
It'd be great if I could do this natively via the Project Factory module. */
module "auto-project-project-metadata" {
  source  = "./modules/gcp-project-metadata"
  project = module.auto-project.project_id
  metadata = {
    enable-oslogin                = "true"
    google-compute-default-region = "${var.gcp_region}"
    google-compute-default-zone   = "${var.gcp_zone}"
  }
}

// Create target project for gated GitOps/CD deployments that require manual review for changes.
module "gated-project" {
  source                  = "terraform-google-modules/project-factory/google"
  version                 = "3.2.0"
  activate_apis           = var.project_services
  apis_authority          = true
  billing_account         = var.gcp_billing_account
  credentials_path        = var.gcp_seed_sa_credentials
  default_service_account = "keep"
  folder_id               = "${module.gcp-seed-project.root_folder}"
  group_name              = "devops"
  lien                    = true
  name                    = "gated-promotion-env"
  org_id                  = var.gcp_organization_id
  random_project_id       = true
}

/* Set project metadata to enable OS login and default instance region/zone.
It'd be great if I could do this natively via the Project Factory module. */
module "gated-project-project-metadata" {
  source  = "./modules/gcp-project-metadata"
  project = module.gated-project.project_id
  metadata = {
    enable-oslogin                = "true"
    google-compute-default-region = "${var.gcp_region}"
    google-compute-default-zone   = "${var.gcp_zone}"
  }
}