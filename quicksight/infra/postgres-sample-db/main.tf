data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail
    dnf update -y
    dnf install -y docker
    systemctl enable --now docker
    docker run -d \
      --restart unless-stopped \
      --name qa-postgres \
      -p 5432:5432 \
      ${var.docker_image}
  EOF
}

resource "aws_instance" "sample_db" {
  ami           = data.aws_ami.al2023.id
  instance_type = var.instance_type
  subnet_id     = local.subnet_id

  vpc_security_group_ids     = [aws_security_group.postgres.id]
  associate_public_ip_address = true

  user_data                  = local.user_data
  user_data_replace_on_change = true

  root_block_device {
    volume_type = "gp3"
    volume_size = 10
  }

  tags = merge(var.tags, {
    Name    = var.project_name
    Purpose = "QuickSight vs Metabase comparison -- runs ${var.docker_image} directly"
  })
}
