provider "aws" {
  region = "${var.region}"
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

# Call application module (security group + EC2 instance)
module "mighty_trousers" {
  source      = "./modules/application"
  vpc_id      = "${aws_vpc.my_vpc.id}"
  subnet_id   = "${aws_subnet.public.id}"
  name        = "MightyTrousers"
  environment = "${var.environment}"
  # Collection of extra security groups (taken from variables.tf)
  extra_sgs   = ["${aws_security_group.default.id}"]
}

# Default security group
resource "aws_security_group" "default" {
  name        = "Default SG"
  description = "Allow SSH access"
  vpc_id      = "${aws_vpc.my_vpc.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
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

# VPC created manually from AWS
data "aws_vpc" "management_layer" {
  id = "vpc-c35aedeb"
}
