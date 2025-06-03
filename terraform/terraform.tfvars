project           = "devops-group22"
credentials_file  = "~/.ssh/devops-group22-f7026c17c139.json"
ssh_pub_key_path  = "~/.ssh/my_gcp_key.pub"
vms = {
  "master-node" = {
    region       = "asia-southeast1"
    zone         = "asia-southeast1-a"
  }
  "worker-node-1" = {
    region       = "us-central1"
    zone         = "us-central1-a"
  }
}

machine_type      = "e2-medium"
disk_image        = "ubuntu-2004-focal-v20250408"
disk_size         = 10

subnets = {
  "asia-southeast1" = "10.10.0.0/16"
  "us-central1"     = "10.20.0.0/16"
}
