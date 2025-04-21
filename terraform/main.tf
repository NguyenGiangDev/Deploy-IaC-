provider "google" {
  credentials = file(var.credentials_file)
  project     = var.project
  region      = var.region
}

resource "google_compute_instance" "vm_instance" {
  for_each     = toset(var.vm_names)
  name         = each.key
  machine_type = var.machine_type
  zone         = var.zone

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
    network = "default"
    access_config {}
  }

  tags = ["k8s"]
}

output "vm_ips" {
  value = {
    for name, inst in google_compute_instance.vm_instance :
    name => inst.network_interface[0].access_config[0].nat_ip
  }
}
