provider "aws" {
	region = "eu-central-1"

}

# EC2 instance configuration
resource "aws_instance" "hello-instance" {
	ami = "ami-9bf712f4"
	instance_type = "t2.micro"
	
	tags {
		Name = "hello_instance"
	}
}
