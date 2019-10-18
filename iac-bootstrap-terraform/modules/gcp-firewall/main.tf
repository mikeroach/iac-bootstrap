/* This module configures firewall rules for the management VPC. While it's sloppy
to hardcode the values, I'd rather spend my time on the application/infrastructure
pipelines that will run from this environment - and it's better to have firewall
rules implemented by a sloppy singleton module than have no firewall rules at all.

TOOD: Break this out into a Terraservice-pattern module with parameterized input. */

/* Unfortunately GCP doesn't support specifying ICMP type in firewall rules. I only
want to allow TTL exceeded, fragmentation needed but DF set, and redirects but must
instead enable the entire ICMP family to avoid breaking legitimate connectivity. */
resource "google_compute_firewall" "allow-all-icmp" {
  name          = "allow-all-icmp"
  description   = "Allow ICMP from anywhere (restrict type upon GCP support!)"
  project       = var.gcp_project
  network       = var.network
  direction     = "INGRESS"
  priority      = "1000"
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "icmp"
  }
}

// Allow all internal traffic from the management network
resource "google_compute_firewall" "allow-internal-mgmt-traffic" {
  name          = "allow-internal-mgmt-traffic"
  description   = "Allow internal management traffic"
  project       = var.gcp_project
  network       = var.network
  direction     = "INGRESS"
  priority      = "1000"
  source_ranges = ["10.0.0.0/24"]

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
}

// Allow external management traffic from trusted networks
resource "google_compute_firewall" "allow-trusted" {
  name          = "allow-external-trusted"
  description   = "Allow external management from trusted networks"
  project       = var.gcp_project
  network       = var.network
  direction     = "INGRESS"
  priority      = "1000"
  source_ranges = var.trusted_networks

  allow {
    protocol = "tcp"
    ports    = ["22", "2375-2376", "8080"]
  }
}