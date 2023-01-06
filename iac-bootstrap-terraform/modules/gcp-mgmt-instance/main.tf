/* This module manages a GCP instance for our build and management Docker
host along with a compute disk for its persistent data. It needs a local
copy of the IaC Bootstrap Salt State+Pillar repository to set system
configuration via the file and salt-masterless provisoners. */

// Create a persistent disk to host our Docker volume data.
resource "google_compute_disk" "mgmt_docker_volume" {
  name    = "${var.machine_name}-docker-volumes"
  project = var.gcp_project
  size    = var.docker_volume_size
  type    = "pd-standard"
  zone    = var.gcp_zone
  lifecycle {
    prevent_destroy = true
  }
}

/* Managing the disk attachment this way prevented bootstrapping a new
instance with an existing persistent disk, so I had to manage the disk
attachment from within the instance resource instead.

resource "google_compute_attached_disk" "mgmt_docker_volume_attachment" {
  disk     = google_compute_disk.mgmt_docker_volume.self_link
  instance = google_compute_instance.mgmt-instance.self_link
}
*/

locals {
  provisioner_host        = google_compute_instance.mgmt-instance.network_interface.0.access_config.0.nat_ip
  provisioner_type        = "ssh"
  provisioner_user        = "sa_${file(var.gcp_seed_sa_id)}"
  provisioner_private_key = "${file(var.gcp_seed_sa_privkey)}"
}

resource "google_compute_instance" "mgmt-instance" {
  name                      = var.machine_name
  project                   = var.gcp_project
  machine_type              = var.machine_type
  zone                      = var.gcp_zone
  allow_stopping_for_update = true

  /* Preemptive instances sounded good for cost savings in theory, but turned out
  poorly in practice for my persistent singleton build instance use case after
  preemption interrupted several CD jobs. Better to stay non-preemptible for
  less failures and take care to only run the meter when actively developing. */
  scheduling {
    preemptible         = var.preemptible == true ? true : false            // Preemptible instances aren't eligible for Always Free pricing.
    on_host_maintenance = var.preemptible == true ? "TERMINATE" : "MIGRATE" // Must be TERMINATE for preemptible instances.
    automatic_restart   = var.preemptible == true ? false : true            // Must be false for preemptible instances.
  }

  boot_disk {
    initialize_params {
      size  = "10"
      type  = "pd-standard"
      image = "ubuntu-os-cloud/ubuntu-minimal-1804-lts"
    }
  }

  network_interface {
    subnetwork         = var.subnet
    subnetwork_project = var.gcp_project
    access_config {
      // Omitting "nat_ip" in access_config will use an ephemeral IP.

      /* If total monthly egress traffic volume is <1GB, premium tier costs
         less than standard tier since it falls under Always Free pricing. */
      network_tier = "PREMIUM"
    }
  }

  /* Per https://www.terraform.io/docs/providers/google/r/compute_attached_disk.html :
  When using compute_attached_disk you *MUST* use lifecycle.ignore_changes = ["attached_disk"]
  on the compute_instance resource that has the disks attached. Otherwise the two resources will
  fight for control of the attached disk block.

  lifecycle {
    ignore_changes = ["attached_disk"]
  }
  */

  // Managing the persistent disk attachment separately didn't work when reprovisioning instances.
  attached_disk {
    source = google_compute_disk.mgmt_docker_volume.self_link
  }

  /* Don't set instance metadata when managed by GCP OS Login.
  metadata = {
    sshKeys = "$username: ssh-rsa $pubkey $email"
  }
  */

  // Define connection method for the following provisioners.
  connection {
    host        = google_compute_instance.mgmt-instance.network_interface.0.access_config.0.nat_ip
    type        = "ssh"
    user        = "sa_${file(var.gcp_seed_sa_id)}"
    private_key = file(var.gcp_seed_sa_privkey)
  }

  // Copy Salt GPG private key archive to new server.
  provisioner "file" {
    source      = "${var.bootstrap_salt_repo}/secrets/gpgkeys.tar.bz2"
    destination = "/tmp/gpgkeys.tar.bz2"
  }

  // Extract Salt GPG private key archive on new server.
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /etc/salt/",
      "sudo tar jxf /tmp/gpgkeys.tar.bz2 -C /etc/salt/",
      "sudo chmod 700 /etc/salt/gpgkeys",
      "rm /tmp/gpgkeys.tar.bz2",
    ]
  }

  /* FIXME: The Salt-masterless provisioner doesn't seem to be able to interpolate the
  bootstrap_salt_repo variable when resolving local_state_tree and minion_config_file,
  so I hardcoded them to avoid this error when validating TF:
  Error: path '74D93920-ED26-11E3-AC10-0800200C9A66' is invalid: stat 74D93920-ED26-11E3-AC10-0800200C9A66: no such file or directory
  */

  // Configure the new instance from the local copy of the combined Salt repository.
  provisioner "salt-masterless" {
    bootstrap_args     = "-X stable 2019.2"
    local_state_tree   = "../../iac-bootstrap-salt/"                      // This folder structure also includes Pillar data...
    minion_config_file = "../../iac-bootstrap-salt/minion-bootstrap.conf" // ...which the minion bootstrap config references.
    log_level          = "info"
  }

}
