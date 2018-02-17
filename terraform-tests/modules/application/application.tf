#--Application module

# Variables to be used when calling the module (moved to variables file)
# variable "vpc_id" {}
# variable "subnet_id" {}
# variable "name" {}

resource "aws_security_group" "allow_http" {
  name        = "${var.name} allow_http"
  description = "Allow HTTP traffic"
  vpc_id      = "${var.vpc_id}"

  # Inbound rules
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound rules
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# AMI data source
data "aws_ami" "app-ami" {
  most_recent = true
  owners      = ["self"]
}

resource "aws_instance" "app-server" {
  # ami                    = "ami-5652ce39"
  ami                    = "${data.aws_ami.app-ami.id}"
  instance_type          = "${lookup(var.instance_type, var.environment)}"
  subnet_id              = "${var.subnet_id}"
  vpc_security_group_ids = ["${distinct(concat(var.extra_sgs, aws_security_group.allow_http.*.id))}"]
  user_data              = "${data.template_file.user_data.rendered}"

  # Use keypair from template
  key_name = "${var.keypair}"

  # Provisioner for ansible inventory
  provisioner "local-exec" {
    command = "echo ${self.public_ip} >> inventory"
  }

  tags {
    Name = "${var.name}"
  }
}

output "hostname" {
  value = "${aws_instance.app-server.private_dns}"
}

data "template_file" "user_data" {
  template = "${file("${path.module}/user_data.sh.tpl")}"

  vars {
    packages   = "${var.extra_packages}"
    nameserver = "${var.external_nameserver}"
  }

  # Don't destroy the server if the user data changes
  lifecycle {
    ignore_changes = ["user_data"]
  }
}

output "public_ip" {
  value = "${aws_instance.app-server.public_ip}"
}
