variable "project" {
  type    = string
  default = "devops-group22"
}

variable "region" {
  type    = string
  default = "asia-southeast1"
}

variable "zone" {
  type    = string
  default = "asia-southeast1-a"
}

variable "credentials_file" {
  type    = string
  default = "~/.ssh/devops-group22-f7026c17c139.json"
}

variable "ssh_pub_key_path" {
  type    = string
  default = "~/.ssh/my_gcp_key.pub"
}

variable "vms" {
  type = map(object({
    region       = string
    zone         = string
  }))
}


variable "machine_type" {
  type    = string
  default = "e2-medium"
}

variable "disk_image" {
  type    = string
  default = "ubuntu-2004-focal-v20250408"
}

variable "disk_size" {
  type    = number
  default = 10
}

variable "subnets" {
  type =map(string)
}
