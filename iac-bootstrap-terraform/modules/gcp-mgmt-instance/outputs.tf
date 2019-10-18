output "external_ip" {
  description = "External ephemeral IP address of the provisioned management server"
  value       = google_compute_instance.mgmt-instance.network_interface.0.access_config.0.nat_ip
}