provider "aws" {
  region = "eu-central-1"
}

# VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Public subnet
resource "aws_subnet" "public" {
  vpc_id     = "${aws_vpc.my_vpc.id}"
  cidr_block = "10.0.1.0/24"
}

# Security group
resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow HTTP traffic"
  vpc_id      = "${aws_vpc.my_vpc.id}"

  # Inbound rules
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound rules
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 instance configuration
resource "aws_instance" "hello-update-instance" {
  ami           = "ami-5652ce39"
  instance_type = "t2.micro"

  tags {
    Name = "hello-update-instance"
  }
}

resource "aws_instance" "master-instance" {
  ami           = "ami-5652ce39"
  instance_type = "t2.micro"
  subnet_id     = "${aws_subnet.public.id}"
}

resource "aws_instance" "slave-instance" {
  ami           = "ami-5652ce39"
  instance_type = "t2.micro"
  subnet_id     = "${aws_subnet.public.id}"

  tags {
    master_hostname = "${aws_instance.master-instance.private_dns}"
  }

  lifecycle {
    ignore_changes = ["tags"] # Don't update slave instance if master instance is recreated
  }

  # depends_on = ["aws_instance.master-instance"]
}
