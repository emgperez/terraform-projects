provider "aws" {
	user = "${var.aws-user}"
	region = "${var.region}"
	
}

resource "aws_instance" "webserver" {
	ami = "ami-fce3c696"
	instance_type = "t2.micro"
}
