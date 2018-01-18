provider "aws" {
  region = "eu-central-1"
}

# VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Public subnet
resource "aws_subnet" "public" {
	vpc_id = "${aws_vpc.my_vpc.id}"
	cidr_block = "10.0.1.0/24"
	
}

# EC2 instance configuration
# resource "aws_instance" "hello-instance" {
#  ami           = "ami-5652ce39"
#  instance_type = "t2.micro"
#
#  tags {
#    Name = "hello-update_instance"
#  }
#}

