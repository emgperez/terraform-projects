provider "aws" {
  	region = "${var.aws_region}"
	profile = "${var.aws_profile}"
}

# IAM
# S3 Access role
resource "aws_iam_instance_profile" "s3_access" {
	name = "s3_access"
	roles = ["${aws_iam_role.s3_access.name}"]
}

resource "aws_iam_role_policy" "s3_access_policy" {
	name = "s3_access_policy"
	role = "${aws_iam_role.s3_access.id}"
	policy = <<EOF
	{
    		"Version": "2012-10-17",
    		"Statement": [
        	   {
            		"Effect": "Allow",
		        "Action": "s3:*",
            		"Resource": "*"
        	   }  
    		]
	}
	EOF
}

resource "aws_iam_role" "s3_access" {
	name = "s3_access"
	assume_role_policy = <<EOF
	{
		"Version": "2012-10-17",
		"Statement": [
		   {
			"Action": "sts:AssumeRole",
			"Principal": {
			   "Service": "ec2.amazonaws.com"
                   	},
			"Effect": "Allow",
			"Sid": ""
		   }
   		]
	}
	EOF
	
}

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

# S3 VPC Endpoint
resource "aws_vpc_endpoint" "private-s3" {
	vpc_id = "${aws_vpc.vpc.id}"
	service_name = "com.amazonaws.${var.aws_region}.s3"
	route_table_ids = ["${aws_vpc.vpc.main_route_table_id}", "${aws_route_table.public.id}"]
	policy = <<POLICY
	{
    "Statement": [
        {
            "Action": "*",
            "Effect": "Allow",
            "Resource": "*",
            "Principal": "*"
        }
    ]
}
POLICY
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
	route_table_id = "${aws_route_table.public_route.id}"
}

resource "aws_route_table_association" "private2_association" {
	subnet_id = "${aws_subnet.private2.id}"
	route_table_id = "${aws_route_table.public_route.id}"
}

resource "aws_db_subnet_group" "rds_subnetgroup" {
	name = "rds_subnetgroup"
	subnet_ids = ["${aws_subnet.rds1.id}", "${aws_subnet.rds2.id}", "${aws_subnet.rds3.id}"]

	tags {
		Name = "rds_sng"
	}
}

# SECURITY GROUPS
# Public sec. group
resource "aws_security_group" "public" {
	name = "sg_public"
	description = "Sec. group used for public and private instances for balancer access"
	vpc_id = "${aws_vpc.vpc.id}"

	# Rules
	# SSH access
	ingress {
		from_port = 22
		to_port = 22
		protocol = "tcp"
		cidr_blocks = ["${var.localip}"]
	}

	# HTTP
	ingress {
		from_port = 80
		to_port = 80
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]	
	}

	# Outbound Internet Access
	egress {
		from_port = 0
		to_port = 0
		protocol = "-1" # Any protocol
		cidr_block = ["0.0.0.0/0"]
	}	
}

# Private Sec. Group
resource "aws_security_group" "private" {
	name = "sg_private"
	description = "Used for private instances"
	vpc_id = "${aws_vpc.vpc.id}"

	# Access from other sec. groups
	ingress {
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["10.1.0.0/16"]
	}

	egress {
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}

}

# RDS Sec. Group
resource "aws_security_group" "RDS" {
	name = "sg_rds"
	description = "Sec. group for DB instances"
	vpc_id = "${aws_vpc.vpc.id}"

	# Allow SQL access from public, private sec. group
	ingress {
		from_port = 3306
		to_port = 3306
		protocol = "tcp"
		security_groups = ["${aws_security_group.id.public.id}", "${aws_security_group.private.id}"]
	}
}

# DB RDS
resource "aws_db_instance" "db" {
	allocated_storage = 10
	engine = "mysql"
	engine_version = "5.6.27"
	instance_class = "${var.db_instance_class}"
	name = "${var.dbname}"
	username = "${var.dbuser}"
	password = "${var.dbpassword}"
	db_subnet_group_name = "${aws_db_subnet_group.rds_subnetgroup.name}"
	vpc_security_group_ids = ["${aws_security_group.RDS.id}"]

}

# S3 code bucket
resource "aws_s3_bucket" "code" {
	bucket = "${var.domain_name}_code111115"
	acl = "private"
	force_destroy = true
	tags {
		Name = "code bucket"
	}
}


# Compute
# Keypair
resource "aws_key_pair" "auth" {
	key_name = "${var.key_name}"
	public_key = "${file(var.public_key.path)}"
}

# Master dev server (with the initial code and the ansible playbook)
resource "aws_instance" "dev" {
	instance_type "${var.dev_instance_type}"
	ami = "${var.dev_ami}"
	tags 
		Name = "dev"
	}

	key_name = "${aws_key_pair.auth.id}"
	vpc_security_group_ids = ["${aws_security_group.public.id}"]
	iam_instance_profile = "${aws_iam_instance_profile.s3_access.id}"
	subnet_id = "${aws_subnet.public.id}"

	# Write host and vars to ansible hosts file	
	provisioner "local-exec" {
      		command = <<EOD
		cat <<EOF > aws_hosts 
		[dev] 
		${aws_instance.dev.public_ip} 
		[dev:vars] 
		s3code=${aws_s3_bucket.code.bucket} 
		EOF
		EOD
  	}	

	# Run the playbook, waiting 6 minutes for the ec2 instance to start
  	provisioner "local-exec" {
      		command = "sleep 6m && ansible-playbook -i aws_hosts wordpress.yml"
  	}
	
}

# LoadBalancer
resource "aws_elb" "prod" {
	name = "${var.domain_name}-prod-elb"
	subnets = ["${aws_subnet.private1.id}", "${aws_subnet.private2.id}"]
	security_groups = ["${aws_security_group.public.id}"]
	
	listener {
		instance_port = 80
		instance_protocol ="http"
		lb_port = 80
		lb_protocol = "http"

	}

	# Health check
	health_check {
		healthy_threshold = "${var.elb_healthy_threshold}"
		unhealthy_threshold = "${var.elb_unhealthy_threshold}"
		timeout = "${var.elb_timeout}"
		target = "HTTP:80/"
		interval = "${var.elb_interval}"
	
	}

	# Allow multiple zones
	cross_zone_load_balancing = true
	idle_timeout = 400
	connection_draining = true
	connection_draining_timeout = 400

	tags {
		Name = "${var.domain_name}-prod-elb"
	}
}

# AMI for the dev instance, our golden image
resource "random_id" "ami" {
	byte_length = 8
	
}

resource "aws_ami_from_instance" "golden" {
    # Includes cron job to retrieve code from the s3 bucket every 3 minutes
    name = "ami-${random_id.ami.b64}"
    source_instance_id = "${aws_instance.dev.id}"
    provisioner "local-exec" {
      command = <<EOT
cat <<EOF > userdata
#!/bin/bash
/usr/bin/aws s3 sync s3://${aws_s3_bucket.code.bucket} /var/www/html/
/bin/touch /var/spool/cron/root
sudo /bin/echo '*/5 * * * * aws s3 sync s3://${aws_s3_bucket.code.bucket} /var/www/html/' >> /var/spool/cron/root
EOF
EOT
  }
}



# Launch Configuration
resource "aws_launch_configuration" "lc" {
	name_prefix = "lc-"
	image_id = "${aws_ami_from_instance.golden.id}"
	instance_type = "${var.lc_instance_type}"
	security_groups = ["${aws_security_group.private.id}"]
	iam_instance_profile = "${aws_iam_instance_profile.s3_access.id}"
	key_name = "${aws_key_pair.auth.id}"
	user_data = "${file("userdata")}"
	lifecycle {
		create_before_destroy = true
	}
}

# Autoscaling group
resource "random_id" "asg" {
	byte_length = 8
}

resource "aws_autoscaling_group" "asg" {
	availability_zones = ["${var.aws_region}a", "${var.aws_region}c"]
	name = "asg-${aws_launch_configuration.lc.id}"
	max_size = "${var.asg_max}"
	min_size = "${var.asg_min}"
	health_check_grace_period = "${var.asg_grace}"
	health_check_type = "${var.asg_hct}"
	desired_capacity = "${var.asg_cap}"
	force_delete = true
	load_balancers = ["${aws_elb.prod.id}"]
	vpc_zone_identifier = ["${aws_subnet.private1.id}", "${aws_subnet.private2.id}"]
	launch_configuration = "${aws_launch_configuration.lc.name}"

	tag {
		key = "Name"
		value = "asg-instance"
		propagate_at_launch = true
	
	}
	
	lifecycle {
		create_before_destroy = true
	}
}

# Route53 records
# Primary zone
# www alias
# dev alias
# database record


