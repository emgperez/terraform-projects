provider "aws" {
	region = "eu-central-1"

}

# EC2 instance configuration
resource "aws_instance" "hello-instance" {
	ami = "ami-b73b63a0"
	instance_type = "t2.micro"
	
	tags {
		Name = "hello_instance"
	}
}
