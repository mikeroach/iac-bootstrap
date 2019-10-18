// This module manages Docker containers running on our build/admin host (currently just Jenkins).

/* FIXME: Add ca_material once we publish DNS hostname; meanwhile omitting it
will disable server certificate validation when connecting to a dynamic IP that
doesn't match the issued certificate's common name.

UPDATE: Even though we now have a DDNS hostname, I'd still rather set host
connection info from the admin1 module output. */

provider "docker" {
  host          = "tcp://${var.docker_host}:2376"
  version       = "2.2.0"
  cert_material = file(var.docker_client_cert)
  key_material  = file(var.docker_client_key)
}

/* Keying the docker_image resource off the registry_image data source seems hokey,
but I found it necessary in order to restart the container with an updated image
during a single Terraform plan/apply cycle. */
data "docker_registry_image" "jenkins" {
  name = var.docker_jenkins_image
}

resource "docker_image" "jenkins" {
  name          = "${data.docker_registry_image.jenkins.name}"
  keep_locally  = true
  pull_triggers = ["${data.docker_registry_image.jenkins.name}"]
}

/* Create a Docker volume to store our persistent Jenkins data. Docker's
data root directory is configured by Salt to use the GCP instance's
persistent disk created via the gcp-mgmt-instance module. */
resource "docker_volume" "jenkins-home" {
  name = "jenkins-home"
  lifecycle {
    prevent_destroy = true
  }
}

/* NB: "Latest" here is the Terraform provider attribute reference for the ID
of the specified docker_image resource, NOT a tag. */
resource "docker_container" "jenkins" {
  name     = "jenkins"
  image    = "${docker_image.jenkins.latest}"
  env      = var.docker_jenkins_envvars
  must_run = true
  restart  = "unless-stopped"
  rm       = false
  start    = true
  user     = "root"
  // FIXME: Correctly map user/permissions to Docker socket to run as unprivileged user.
  mounts {
    target = "/var/run/docker.sock"
    source = "/var/run/docker.sock"
    type   = "bind"
  }
  ports {
    internal = 8080
    external = 8080
  }
  volumes {
    volume_name    = docker_volume.jenkins-home.name
    container_path = "/var/jenkins_home"
  }

}
