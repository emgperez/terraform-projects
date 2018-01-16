provider "aws" {
  	region = "${var.aws_region}"
	profile = "${var.aws_profile}"
}

# IAM
# S3 Access role

# VPC
resource "aws_vpc" "vpc" {
	cidr_block = "10.1.0.0/16"
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
	vpc_id = "${aws_vpc.vpc.id}"
}

# Public route table
resource "aws_route_table" "public_route" {
	vpc_id = "${aws_vpc.vpc.id}"

	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = "${aws_internet_gateway.igw.id}"
	}
	tags {
		Name = "public"
	}
}

# Private route table
# Subnets
# Public subnets
# Private subnets x2
# RDS subnet 1
# RDS subnet 2
# RDS subnet 3

# SECURITY GROUPS
# Public
# RDS

# S3 code bucket

# Compute
# Keypair
# Master dev server (with the initial code and the ansible playbook)
# LoadBalancer
# AMI for the dev instance
# Launch Configuration
# Autoscaling group

# Route53 records
# Primary zone
# www alias
# dev alias
# database record


