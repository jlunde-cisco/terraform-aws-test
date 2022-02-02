terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "3.47.0"
    }
    awx = {
      source = "nolte/awx"
      version = "0.2.2"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}
variable "instance_name" {
    default = "lund-bastion"
}

variable "pvt_key" {}
variable "pub_key" {}

resource "aws_instance" "vm" {
  
  ami           = "ami-0fb653ca2d3203ac1"
  instance_type = "t2.micro"
  key_name = "login"
  security_groups = ["terraform-sg-1"]

  tags = {
    Name = var.instance_name

} 
provisioner "remote-exec" {
    inline = ["sudo apt update", "sudo apt install python3 -y", "echo Done!"]

    connection {
      host        = self.public_ip
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.pvt_key)
    }
  }

provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu -i '${self.public_ip},' --private-key ${var.pvt_key} -e 'pub_key=${var.pub_key}' terraform-install.yml"
  }
}

resource "aws_security_group" "terraform-sg-1" {
  name        = "terraform-sg-1"
  description = "Created by Terraform"
  vpc_id      = "vpc-e933b282"

  ingress {
    description      = "Allow SSH IN"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}
