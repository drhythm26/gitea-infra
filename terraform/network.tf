resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "public" {
  name          = "public-subnet"
  network       = google_compute_network.vpc.id
  region        = var.region
  ip_cidr_range = "10.0.1.0/24"
}

resource "google_compute_subnetwork" "app" {
  name          = "app-subnet"
  network       = google_compute_network.vpc.id
  region        = var.region
  ip_cidr_range = "10.0.2.0/24"
}

resource "google_compute_subnetwork" "data" {
  name          = "data-subnet"
  network       = google_compute_network.vpc.id
  region        = var.region
  ip_cidr_range = "10.0.3.0/24"
}

resource "google_compute_subnetwork" "monitor" {
  name          = "monitor-subnet"
  network       = google_compute_network.vpc.id
  region        = var.region
  ip_cidr_range = "10.0.4.0/24"
}

resource "google_compute_firewall" "allow_ssh_bastion" {
  name    = "allow-ssh-bastion"
  network = google_compute_network.vpc.id
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = var.admin_cidr
  target_tags   = ["bastion"]
}

resource "google_compute_firewall" "allow_ssh_internal" {
  name    = "allow-ssh-internal"
  network = google_compute_network.vpc.id
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_tags = ["bastion"]
  target_tags = ["internal"]
}

resource "google_compute_firewall" "allow_web" {
  name    = "allow-web"
  network = google_compute_network.vpc.id
  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["gitea-server"]
}

resource "google_compute_firewall" "allow_mysql" {
  name    = "allow-mysql"
  network = google_compute_network.vpc.id
  allow {
    protocol = "tcp"
    ports    = ["3306"]
  }
  source_tags = ["gitea-server"]
  target_tags = ["mysql-server"]
}

resource "google_compute_firewall" "allow_monitoring" {
  name    = "allow-monitoring"
  network = google_compute_network.vpc.id
  allow {
    protocol = "tcp"
    ports    = ["9100"]
  }
  source_tags = ["monitor"]
  target_tags = ["internal"]
}