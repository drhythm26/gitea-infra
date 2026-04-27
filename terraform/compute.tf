locals {
  common_metadata = {
    ssh-keys               = "${var.ssh_user}:${file(pathexpand(var.ssh_public_key_path))}"
    block-project-ssh-keys = "true"
  }
  common_labels = {
    project = "gitea"
    env     = var.environment
  }
}

resource "google_compute_instance" "bastion" {
  name         = "bastion"
  machine_type = "e2-micro"
  zone         = var.zone
  tags         = ["bastion"]
  boot_disk {
    initialize_params {
      image = "${var.image_project}/${var.image_family}"
      size  = 20
      type  = "pd-balanced"
    }
  }
  network_interface {
    subnetwork = google_compute_subnetwork.public.id
    network_ip = "10.0.1.10"
    access_config {}
  }
  metadata = local.common_metadata
  labels   = merge(local.common_labels, { role = "bastion" })
}

resource "google_compute_instance" "gitea" {
  name         = "gitea-server"
  machine_type = "e2-medium"
  zone         = var.zone
  tags         = ["gitea-server", "internal"]
  boot_disk {
    initialize_params {
      image = "${var.image_project}/${var.image_family}"
      size  = 20
      type  = "pd-balanced"
    }
  }
  network_interface {
    subnetwork = google_compute_subnetwork.app.id
    network_ip = "10.0.2.10"
    access_config {}
  }
  metadata = local.common_metadata
  labels   = merge(local.common_labels, { role = "gitea" })
}

resource "google_compute_instance" "mysql" {
  name         = "mysql-server"
  machine_type = "e2-medium"
  zone         = var.zone
  tags         = ["mysql-server", "internal"]
  boot_disk {
    initialize_params {
      image = "${var.image_project}/${var.image_family}"
      size  = 30
      type  = "pd-balanced"
    }
  }
  network_interface {
    subnetwork = google_compute_subnetwork.data.id
    network_ip = "10.0.3.10"
  }
  metadata = local.common_metadata
  labels   = merge(local.common_labels, { role = "mysql" })
}

resource "google_compute_instance" "monitor" {
  name         = "monitor"
  machine_type = "e2-small"
  zone         = var.zone
  tags         = ["monitor", "internal"]
  boot_disk {
    initialize_params {
      image = "${var.image_project}/${var.image_family}"
      size  = 30
      type  = "pd-balanced"
    }
  }
  network_interface {
    subnetwork = google_compute_subnetwork.monitor.id
    network_ip = "10.0.4.10"
  }
  metadata = local.common_metadata
  labels   = merge(local.common_labels, { role = "monitor" })
}