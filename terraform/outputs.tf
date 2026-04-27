output "bastion_public_ip" {
  value = google_compute_instance.bastion.network_interface[0].access_config[0].nat_ip
}
output "gitea_public_ip" {
  value = google_compute_instance.gitea.network_interface[0].access_config[0].nat_ip
}
output "gitea_internal_ip" {
  value = google_compute_instance.gitea.network_interface[0].network_ip
}
output "mysql_internal_ip" {
  value = google_compute_instance.mysql.network_interface[0].network_ip
}
output "monitor_internal_ip" {
  value = google_compute_instance.monitor.network_interface[0].network_ip
}