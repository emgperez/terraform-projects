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
resource "aws_default_route_table" "private_route" {
	default_route_table_id = "${aws_vpc.vpc.default_route_table_id}"
	tags {
		Name = "private"
	}
	
}

# Subnets
# Public subnets
resource "aws_subnet" "public" {
	vpc_id = "${aws_vpc.vpc.id}"
	cidr_block = "10.1.1.0/24"
	map_public_ip_on_launch = true
	availability_zone = "us-east-1d"

	tags {
		Name = "public"
	}
}

# Private subnets x2
resource "aws_subnet" "private1" {
	vpc_id = "${aws_vpc.vpc.id}"
	cidr_block = "10.1.2.0/24"
	map_public_ip_on_launch = false
	availability_zone = "us-east-1a"

	tags {
		Name = "private1"
	}
}

resource "aws_subnet" "private2" {
	vpc_id = "${aws_vpc.vpc.id}"
	cidr_block = "10.1.3.0/24"
	map_public_ip_on_launch = false
	availability_zone = "us-east-1c"

	tags {
		Name = "private2"
	}
}

# RDS subnet 1
resource "aws_subnet" "rds_subnet_1" {
	vpc_id = "${aws_vpc.vpc.id}"
	cidr_block = "10.1.4.0/24"
	map_public_ip_on_launch = false
	availability_zone = "us-east-1a"

	tags {
		Name = "rds1"
	}
}

# RDS subnet 2
resource "aws_subnet" "rds_subnet_2" {
	vpc_id = "${aws_vpc.vpc.id}"
	cidr_block = "10.1.5.0/24"
	map_public_ip_on_launch = false
	availability_zone = "us-east-1c"

	tags {
		Name = "rds2"
	}
}

# RDS subnet 3
resource "aws_subnet" "rds_subnet_3" {
	vpc_id = "${aws_vpc.vpc.id}"
	cidr_block = "10.1.6.0/24"
	map_public_ip_on_launch = false
	availability_zone = "us-east-1d"

	tags {
		Name = "rds3"
	}
}

# Subnet associations with route tables
resource "aws_route_table_association" "public_association" {
	subnet_id = "${aws_subnet.public.id}"
	route_table_id = "${aws_route_table.public_route.id}"
}

resource "aws_route_table_association" "private1_association" {
	subnet_id = "${aws_subnet.private1.id}"
	route_table_id = "${aws_route_table.private_route.id}"
}

resource "aws_route_table_association" "private2_association" {
	subnet_id = "${aws_subnet.private2.id}"
	route_table_id = "${aws_route_table.private_route.id}"
}


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


