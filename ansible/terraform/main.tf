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

locals {
  ports = [53, 22, 80, 443, 6443, 10250, 10256, 10257, 10259, 2379, 10248, 10249]
}

resource "scaleway_instance_ip" "master_ipv4" {
  project_id = var.project_id
}

resource "scaleway_instance_ip" "node_ipv4" {
  project_id = var.project_id
}

resource "scaleway_instance_security_group" "k8s" {
  project_id              = var.project_id
  inbound_default_policy  = "drop"
  outbound_default_policy = "accept"

    dynamic "inbound_rule" {
      for_each = local.ports
      content {
          action = "accept"
          port   = inbound_rule.value
      }
    }
}

data "template_file" "example" {
  template = "${file("${path.module}/../ssh/id_rsa.pub")}"
}

output "rendered" {
  value = "${data.template_file.example.rendered}"
}

resource "scaleway_account_ssh_key" "main" {
    name        = "terraform"
    public_key = "${file("${path.module}/../ssh/id_rsa.pub")}"
}

resource "scaleway_instance_server" "k8s_master" {
  project_id = var.project_id
  type       = "DEV1-M"
  image      = "ubuntu_focal"

  tags = ["kubernetes", "role=master", "terraform", "ansible"]

  ip_id = scaleway_instance_ip.master_ipv4.id

  # additional_volume_ids = [scaleway_instance_volume.data.id]

  root_volume {
    # The local storage of a DEV1-L instance is 80 GB, subtract 30 GB from the additional l_ssd volume, then the root volume needs to be 50 GB.
    size_in_gb = 40
  }

  security_group_id = scaleway_instance_security_group.k8s.id
}


resource "scaleway_instance_server" "k8s_node" {
  project_id = var.project_id
  type       = "DEV1-M"
  image      = "ubuntu_focal"

  tags = ["kubernetes", "role=node", "terraform", "ansible"]

  ip_id = scaleway_instance_ip.node_ipv4.id

  # additional_volume_ids = [scaleway_instance_volume.data.id]

  root_volume {
    # The local storage of a DEV1-L instance is 80 GB, subtract 30 GB from the additional l_ssd volume, then the root volume needs to be 50 GB.
    size_in_gb = 40
  }

  security_group_id = scaleway_instance_security_group.k8s.id
}

output "master_ipv4" {
  description = "Public IP address of an instance."
  value = "${scaleway_instance_ip.master_ipv4.address}:master"
}

output "node_ipv4" {
  description = "Public IP address of a Kubernetes node instance."
  value = "${scaleway_instance_ip.node_ipv4.address}:node"
}

# ansible-playbook rola -e SCW_ACCESS_KEY="SCWN2YGGEBNH0VGRXNR1" SCW_SECRET_KEY="dc884e51-462c-4bda-b679-32bd7d2ed4bc" -e TF_VAR_project_id="431d432b-1849-445f-a66b-7d1ccdf5d34a"  
