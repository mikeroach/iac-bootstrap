variable "bootstrap_salt_repo" {
  type        = string
  description = "File path to local IaC bootstrap Salt combined state+pillar repository. Omit trailing slash"
}

variable "docker_volume_size" {
  type        = string
  description = "Size in GB of the persistent disk to create and attach to our IaC management server for storing Docker volumes"
}

variable "gcp_project" {
  type        = string
  description = "Google Cloud Platform project to house our IaC management servers"
}

variable "gcp_seed_sa_id" {
  type        = string
  description = "File path to GCP seed service account userid. Created by the gcp-seed-project module"
}

variable "gcp_seed_sa_privkey" {
  type        = string
  description = "File path to GCP seed service account SSH private key. Created by the gcp-seed-project module"
}

variable "gcp_zone" {
  type        = string
  description = "Google Cloud Platform compute zone to launch our IaC management servers per https://cloud.google.com/compute/docs/regions-zones/"
}

variable "machine_name" {
  type        = string
  description = "Name of our single IaC management server"
}

variable "machine_type" {
  type        = string
  description = "Google Cloud Platform machine type for our IaC management servers per https://cloud.google.com/compute/docs/machine-types"
}

variable "preemptible" {
  type        = bool
  description = "Define whether our IaC management server will run as preemptible (less compute-hour cost at the expense of availability)"
}

variable "subnet" {
  type        = string
  description = "VPC subnet to host our IaC management servers"
}
