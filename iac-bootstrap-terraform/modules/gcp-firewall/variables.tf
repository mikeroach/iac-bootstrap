variable "gcp_project" {
  type        = string
  description = "Google Cloud Platform project to house our IaC management servers"
}

variable "network" {
  type        = string
  description = "VPC network to host our IaC management servers"
}

variable "trusted_networks" {
  type        = set(string)
  description = "CIDR of trusted source networks from which to allow all management traffic"
}