provider "aws" {
  region = "${var.region}"
}

# VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "${var.vpc_cidr}"
}

# VPC peering
resource "aws_vpc_peering_connection" "my_vpc_management" {
  peer_vpc_id = "${data.aws_vpc.management_layer.id}"
  vpc_id      = "${aws_vpc.my_vpc.id}"
  auto_accept = true
}

# Public subnets
resource "aws_subnet" "public" {
  vpc_id                  = "${aws_vpc.my_vpc.id}"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public-1" {
  vpc_id                  = "${aws_vpc.my_vpc.id}"
  availability_zone	  = "eu-central-1a"
  cidr_block              = "${lookup(var.subnet_cidrs, "eu-central-1a-public")}"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public-2" {
  vpc_id                  = "${aws_vpc.my_vpc.id}"
  availability_zone       = "eu-central-1b"
  cidr_block              = "${lookup(var.subnet_cidrs, "eu-central-1b-public")}"
  map_public_ip_on_launch = true
}



# Kubernetes pod
resource "kubernetes_resource" "mykubpod" {
  cluster    = "${kubernetes_cluster.main.cluster}"
  collection = "pods"
  name       = "mykubpod"
  content    = "${file("mypod.yml")}"
}

# Call application module (security group + EC2 instance)
module "mighty_trousers" {
  source      = "./modules/application"
  vpc_id      = "${aws_vpc.my_vpc.id}"
  subnet_id   = "${aws_subnet.public.id}"
  name        = "MightyTrousers"
  environment = "${var.environment}"

  # Keypair from the root template
  keypair = "${aws_key_pair.terraform.key_name}"

  # Collection of extra security groups (taken from variables.tf)
  extra_sgs = ["${aws_security_group.default.id}"]

  # Instance count (2 instances)
  instance_count = 2
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

# Upload public SSH key from its file (template application -> file() function)
resource "aws_key_pair" "terraform" {
  key_name   = "terraform"
  public_key = "${file("./id_rsa.pub")}"
}

# Igw
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.my_vpc.id}"
}

# Default Route Table with the internet gateway
resource "aws_default_route_table" "default_routing" {
  default_route_table_id = "${aws_vpc.my_vpc.default_route_table_id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }
}

# S3 bucket policy
resource "aws_iam_role_policy" "s3-assets-all" {
  name   = "s3assets@@all"
  role   = "${aws_iam_role.app-production.id}"
  policy = "${file("policies/s3assets@@all.json")}"
}

output "mighty_trousers_public_ip" {
  value = "${module.mighty_trousers.public_ip}"
}
