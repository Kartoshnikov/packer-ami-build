packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.2"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "AWS_REGION" { type = string }
variable "PACKER_VPC_NAME" { type = string }
variable "ADMIN_SSH_PUBLIC_KEY" { type = string }

source "amazon-ebs" "linux" {
  ami_name      = "ExampleWorker{{timestamp}}"
  vpc_filter {filters = {"tag:Name": var.PACKER_VPC_NAME}}
  subnet_filter {
    filters = {
      "tag:Name": "example-packer-public-sub-*"
    }
    most_free = true
    random = true
  }

  instance_type = "t3a.medium"
  launch_block_device_mappings {
    device_name = "/dev/sda1"
    volume_size = 20
    volume_type = "gp2"
    delete_on_termination = true
  }
  run_volume_tags = {
    Project = "Example"
    Name    = "ExampleWorker"
  }
  tags = {
    Project = "Example"
    Name    = "ExampleWorker"
  }

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-bionic-18.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  ssh_username = "ubuntu"
}

build {
  name = "Example-packer"
  sources = [
    "source.amazon-ebs.linux"
  ]
  provisioner "file" {
    source      = "./configs"
    destination = "/tmp"
  }

  provisioner "shell" {
    environment_vars = [
      "AWS_REGION=${var.AWS_REGION}",
      "ADMIN_SSH_PUBLIC_KEY=${var.ADMIN_SSH_PUBLIC_KEY}"
    ]
    script = "scripts/setup_worker.sh"
  }
}