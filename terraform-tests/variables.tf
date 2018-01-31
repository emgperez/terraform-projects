variable "region" {
  description = "AWS region. If changed, it will lead to loss of the complete stack of resources."

  # Default value
  default = "eu-central-1"
}

variable "vpc_id" {}
variable "subnet_id" {}
variable "name" {}

variable "environment" {
  default = "prod"
}

variable "allow_ssh_access" {
  description = "List of CIDR blocks that can access instances via SSH"
  default     = ["0.0.0.0/0"]
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "subnet_cidrs" {
  description = "CIDR blocks for public and private subnets"

  default = {
    public  = "10.0.1.0/24"
    private = "10.0.2.0/24"
  }
}

variable "instance_type" {
  type = "map"

  default = {
    dev  = "t2.micro"
    test = "t2.medium"
    prod = "t2.large"
  }
}

variable "extra_sgs" {
  default = []
}

# DNS server (google's)
variable "external_nameserver" { default = "8.8.8.8" }
variable "extra_packages" {
  description = "Additional packages to install for particular module"
  default = {
    MightyTrousers = "wget bind-utils"
  }
}

