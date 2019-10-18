variable "docker_host" {
  type        = string
  description = "Hostname/IP of Docker server where our managed containers will run. Used by Docker provider configuration"
}

variable "docker_client_cert" {
  type        = string
  description = "File path to client certificate used by Docker provider for TLS connection to Docker host"
}

variable "docker_client_key" {
  type        = string
  description = "File path to client private key used by Docker provider for TLS connection to Docker host"
}

variable "docker_jenkins_image" {
  type        = string
  description = "Registry path to Jenkins container image"
  default     = "$dockerhub_username/$image_name:$tag"
}

variable "docker_jenkins_envvars" {
  type        = list(string)
  description = "Environment variables that will be injected into the Jenkins container at runtime. Watch out! Anyone who has access to inspect the running Docker container can see secret credentials supplied this way"
  default     = ["ENVVARS=UNPOPULATED"]
}