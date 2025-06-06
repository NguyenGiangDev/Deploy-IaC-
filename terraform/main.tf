provider "google" {
  credentials = file(var.credentials_file)
  project     = var.project
  region      = "us-central1" # dummy default
}

resource "google_compute_network" "custom_vpc" {
  name                    = "devops-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnets" {
  for_each = var.subnets

  name          = "subnet-${each.key}"
  ip_cidr_range = each.value
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

  # Gán tag k8s cho tất cả, thêm master cho master-node
  tags = contains([each.key], "master-node") ? ["k8s", "master"] : ["k8s"]
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
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["k8s"]
}

resource "google_compute_firewall" "allow-k8s-api" {
  name    = "allow-k8s-api"
  network = google_compute_network.custom_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["6443"]
  }

  source_ranges = ["10.0.0.0/8"] # Hoặc thay bằng CIDR phù hợp với subnet bạn dùng
  target_tags   = ["master"]
}

resource "google_compute_firewall" "allow-weave-tcp" {
  name    = "allow-weave-tcp"
  network = google_compute_network.custom_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["6783"]
  }

  source_ranges = ["10.0.0.0/8"]
  target_tags   = ["k8s"]
}

resource "google_compute_firewall" "allow-weave-udp" {
  name    = "allow-weave-udp"
  network = google_compute_network.custom_vpc.id

  allow {
    protocol = "udp"
    ports    = ["6783", "6784"]
  }

  source_ranges = ["10.0.0.0/8"]
  target_tags   = ["k8s"]
}
