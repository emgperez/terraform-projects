variable "region" {
  description = "AWS region. If changed, it will lead to loss of the complete stack of resources."

  # Default value
  default = "eu-central-1"
}

variable "vpc_id" {}
variable "subnet_id" {}
variable "name" {}
variable "environment" { default = "dev" }
variable "instance_type" {
  type = "map"
  default = {
    dev = "t2.micro"
    test = "t2.medium"
    prod = "t2.large"
  }
} 
