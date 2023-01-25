variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "ssh_public_key" {
  description = "SSH public key"
  type        = string
}

variable "custom_tags" {
  description = "Custom k8s spot instances tags"
  type        = map(any)
}

# main code execution section 
provider "aws" {
  region = var.aws_region
}


resource "aws_key_pair" "this" {
  key_name   = "spot-ssh-key"
  public_key = templatefile("${var.ssh_public_key}", {})
}

resource "aws_vpc" "this" {
  cidr_block = "172.16.0.0/16"

  tags = var.custom_tags
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = var.custom_tags

}
resource "aws_route_table" "this" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }


    tags = var.custom_tags

}
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.this.id
  route_table_id = aws_route_table.this.id
}

resource "aws_subnet" "this" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "172.16.10.0/24"
  availability_zone = "${var.aws_region}a"

  tags = var.custom_tags
}

locals {
  # Ids for multiple sets of EC2 instances, merged together
  allowed_tcp_ports = ["80", "8080"]
  allow_ssh_port    = ["22"]
}

resource "aws_security_group" "this" {
  name        = "Server Spot K8s Security Group"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.this.id

  dynamic "ingress" {
    for_each = local.allowed_tcp_ports

    content {
      description = "Allow incoming TCP traffic"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      # Please restrict your ingress to only necessary IPs and ports.
      # Opening to 0.0.0.0/0 can lead to security vulnerabilities.

      cidr_blocks = ["0.0.0.0/0"] # add a CIDR block here
      # security_groups = list(var.alb_security_group_id)
    }
  }

  dynamic "ingress" {
    for_each = local.allow_ssh_port

    content {
      description = "Allow incoming SSH traffic"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      # Please restrict your ingress to only necessary IPs and ports.
      # Opening to 0.0.0.0/0 can lead to security vulnerabilities.

      cidr_blocks = ["0.0.0.0/0"] # add a CIDR block here
      # security_groups = list(var.alb_security_group_id)
    }
  }

  dynamic "egress" {
    for_each = local.allowed_tcp_ports

    content {
      description = "Allow all outbound traffic"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = var.custom_tags
}

# Request a spot instance at $0.02
resource "aws_spot_instance_request" "cheap_worker" {
  ami                         = "ami-076bdd070268f9b8d"
  spot_price                  = "0.03"
  instance_type               = "t2.medium"
  spot_type                   = "one-time"
  associate_public_ip_address = true
  vpc_security_group_ids = [
    aws_security_group.this.id
  ]
  subnet_id = aws_subnet.this.id
  tags      = var.custom_tags


}
