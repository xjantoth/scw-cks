variable "project_id" {
  type        = string
  description = "Your project ID."
}

terraform {
  required_providers {
    scaleway = {
      source = "scaleway/scaleway"
    }
  }
  required_version = ">= 0.13"
}

provider "scaleway" {
  zone   = "fr-par-1"
  region = "fr-par"
}

resource "scaleway_instance_ip" "public_ip" {
  project_id = var.project_id
}

#resource "scaleway_instance_volume" "data" {
#  project_id = var.project_id
#  size_in_gb = 20
#  type       = "l"
#}

resource "scaleway_instance_security_group" "k8s" {
  project_id              = var.project_id
  inbound_default_policy  = "drop"
  outbound_default_policy = "accept"

  inbound_rule {
    action = "accept"
    port   = "22"
  }

  inbound_rule {
    action = "accept"
    port   = "80"
  }

  inbound_rule {
    action = "accept"
    port   = "443"
  }
}

resource "scaleway_instance_server" "k8s_master" {
  project_id = var.project_id
  type       = "DEV1-S"
  image      = "ubuntu_focal"

  tags = ["kubernetes", "master", "terraform", "ansible"]

  ip_id = scaleway_instance_ip.public_ip.id

  # additional_volume_ids = [scaleway_instance_volume.data.id]

  root_volume {
    # The local storage of a DEV1-L instance is 80 GB, subtract 30 GB from the additional l_ssd volume, then the root volume needs to be 50 GB.
    size_in_gb = 20
  }

  security_group_id = scaleway_instance_security_group.k8s.id
}


output "public_ip" {
  description = "Public IP address of an instance."
  value = scaleway_instance_ip.public_ip.address

}



# ansible-playbook rola -e SCW_ACCESS_KEY="SCWN2YGGEBNH0VGRXNR1" SCW_SECRET_KEY="dc884e51-462c-4bda-b679-32bd7d2ed4bc" -e TF_VAR_project_id="431d432b-1849-445f-a66b-7d1ccdf5d34a"  
