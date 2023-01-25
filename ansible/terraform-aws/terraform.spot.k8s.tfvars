aws_region     = "eu-central-1"
ssh_public_key = "~/.ssh/spot-k8s.pub"
custom_tags = {
  Name      = "spot-k8s"
  Terraform = "true"
  Delete    = "true"
}
