provider "google" {
  credentials = file(var.credentials_file)
  project     = var.project
  region      = "us-central1"  # dummy default, các VM sẽ override
}

resource "google_compute_network" "custom_vpc" {
  name                    = "devops-vpc"
  auto_create_subnetworks = false
}

# Tạo subnet cho mỗi region
resource "google_compute_subnetwork" "subnets" {
  for_each = {
    for k, v in var.vms : v.region => v
  }

  name          = "subnet-${each.key}"
  ip_cidr_range = "10.${substr(md5(each.key), 0, 2)}.0.0/16"
  network       = google_compute_network.custom_vpc.id
  region        = each.key
}

resource "google_compute_instance" "vm_instance" {
  for_each = var.vms

  name         = each.key
  machine_type = var.machine_type
  zone         = each.value.zone

  boot_disk {
    initialize_params {
      image = var.disk_image
      size  = var.disk_size
    }
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_pub_key_path)}"
  }

  network_interface {
    network    = google_compute_network.custom_vpc.id
    subnetwork = google_compute_subnetwork.subnets[each.value.region].id
    access_config {}
  }

  tags = ["k8s"]
}

resource "google_compute_firewall" "allow-ssh" {
  name    = "allow-ssh"
  network = google_compute_network.custom_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["k8s"]
}

resource "google_compute_firewall" "allow-http" {
  name    = "allow-http"
  network = google_compute_network.custom_vpc.id

  allow {
    protocol = "http"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["k8s"]
}
