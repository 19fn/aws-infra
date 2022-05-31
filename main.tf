# Virtual Private Network
resource "aws_vpc" "vpc" {
	cidr_block = var.cblock_vpc
	
	tags = {
		Environment = "Production"
		Owner = "Federico Cabrera"
		Project = "Endavel"
		ApplicationID = "300622"
	}
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
	vpc_id = aws_vpc.vpc.id

	tags = {
		Environment = "Production"
		Owner = "Federico Cabrera"
		Project = "Endavel"
		ApplicationID = "300622"
	}
}

# frontend Public Subnet
resource "aws_subnet" "public-subnet-1" {
	vpc_id = aws_vpc.vpc.id
	cidr_block = var.cblock_public_subnet
	map_public_ip_on_launch = true

	tags = {
		Environment = "Production"
		Owner = "Federico Cabrera"
		Project = "Endavel"
		ApplicationID = "300622"
	}
}

# backend Private Subnet
resource "aws_subnet" "private-subnet-1" {
    vpc_id = aws_vpc.vpc.id
    cidr_block = var.cblock_private_subnet
	map_public_ip_on_launch = false

	tags = {
		Environment = "Production"
		Owner = "Federico Cabrera"
		Project = "Endavel"
		ApplicationID = "300622"
	}
}

# Public Route Table
resource "aws_route_table" "public-rt" {
	vpc_id = aws_vpc.vpc.id
	
	route {
        	cidr_block = "0.0.0.0/0"
        	gateway_id = aws_internet_gateway.igw.id
   	}

	tags = {
		Environment = "Production"
		Owner = "Federico Cabrera"
		Project = "Endavel"
		ApplicationID = "300622"
	}
}

# Private Route Table
resource "aws_route_table" "private-rt" {
    vpc_id = aws_vpc.vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.natGW.id
    }

	tags = {
		Environment = "Production"
		Owner = "Federico Cabrera"
		Project = "Endavel"
		ApplicationID = "300622"
	}
}

# Public Route Table Association
resource "aws_route_table_association" "public-rta" {
    subnet_id = aws_subnet.public-subnet-1.id
    route_table_id = aws_route_table.public-rt.id
}

# Private Route Table Association
resource "aws_route_table_association" "private-rta" {
    subnet_id = aws_subnet.private-subnet-1.id
    route_table_id = aws_route_table.private-rt.id
}

# Elastic IP
resource "aws_eip" "natIP" {
    vpc = true

	tags = {
		Environment = "Production"
		Owner = "Federico Cabrera"
		Project = "Endavel"
		ApplicationID = "300622"
	}
}

resource "aws_nat_gateway" "natGW" {
    allocation_id = aws_eip.natIP.id
    subnet_id = aws_subnet.public-subnet-1.id
}

# Get latest Ubuntu Linux AMI
data "aws_ami" "ubuntu-linux" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Bastion Host Security Group
resource "aws_security_group" "bastion-sg" {
	depends_on = [
		aws_vpc.vpc
	]

	name        = "sg bastion"
	description = "bastion security group"
	vpc_id      = aws_vpc.vpc.id

	ingress {
		description = "allow SSH"
		from_port   = 22
		to_port     = 22
		protocol    = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	egress {
		from_port   = 0
		to_port     = 0
		protocol    = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}
}

# Bastion Host EC2 Instance
resource "aws_instance" "bastion-host" {
	depends_on = [
		aws_security_group.bastion-sg,
	]
	ami = data.aws_ami.ubuntu-linux.id
	instance_type = var.bastion_instance
	key_name = var.key_pair_bastion
	vpc_security_group_ids = [aws_security_group.bastion-sg.id]
	subnet_id = aws_subnet.public-subnet-1.id
	tags = {
		Environment = "Production"
		Name = "bastion"
		Owner = "Federico Cabrera"
		Project = "Endavel"
		ApplicationID = "300622"
	}

  	provisioner "file" {
    	source      = "/home/fcabrera/Projects/bsquad-infra/fnc_key.pem"
    	destination = "/home/ubuntu/fnc_key.pem"
  	}

	# Remote connection
	connection {
		type = "ssh"
		host = self.public_ip
		user = "ubuntu"
		private_key = file(var.private_key_location)
	}
}

# frontend Security Group
resource "aws_security_group" "frontend-sg" {
    name = "sg frontend"
    description = "Endavel frontend security group to allow inbound/outbound from the VPC"
    vpc_id = aws_vpc.vpc.id

	depends_on = [
    	aws_vpc.vpc
  	]

	# SSH
    ingress {
        description = "ssh"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

	# PHPMYADMIN
    ingress {
        description = "phpMyAdmin"
        from_port = 8081
        to_port = 8081
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }	

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

	tags = {
		Environment = "Production"
		Owner = "Federico Cabrera"
		Project = "Endavel"
		ApplicationID = "300622"
	}
}

# frontend EC2
resource "aws_instance" "frontend" {
	depends_on = [
		aws_security_group.frontend-sg,
		aws_instance.backend
  	]
	ami = data.aws_ami.ubuntu-linux.id
	instance_type = var.frontend_instance
	subnet_id = aws_subnet.public-subnet-1.id
	key_name = var.key_pair_frontend
	vpc_security_group_ids = [aws_security_group.frontend-sg.id]

	user_data = <<EOF
            #!/bin/bash
            apt update
            cd /etc/ && git clone https://github.com/19fn/docker-pack.git && /bin/bash docker-pack/install.sh
            cd /home/ubuntu/ && git clone https://github.com/19fn/local-environment.git
  		EOF
	
	tags = {
		Environment = "Production"
		Name = "frontend"
		Owner = "Federico Cabrera"
		Project = "Endavel"
		ApplicationID = "300622"
	}
}

# backend Security Group
resource "aws_security_group" "backend-sg" {
    name = "sg backend"
    description = "Endavel backend security group to allow inbound/outbound from the VPC"
    vpc_id = aws_vpc.vpc.id

	depends_on = [
    	aws_vpc.vpc
  	]

	# SSH
    ingress {
        description = "ssh"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
		security_groups = [aws_security_group.bastion-sg.id]
    }

	# MYSQL
	ingress {
		description = "mysql"
		from_port = 3306
		to_port = 3306
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
		security_groups = [aws_security_group.frontend-sg.id]
	}
	
	# API
	ingress {
		description = "api"
		from_port = 8080
		to_port = 8080
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
		security_groups = [aws_security_group.frontend-sg.id]
	}

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

	tags = {
		Environment = "Production"
		Owner = "Federico Cabrera"
		Project = "Endavel"
		ApplicationID = "300622"
	}
}

# backend EC2
resource "aws_instance" "backend" {
	ami = data.aws_ami.ubuntu-linux.id
	instance_type = var.backend_instance
	subnet_id = aws_subnet.private-subnet-1.id
	key_name = var.key_pair_backend
	vpc_security_group_ids = [aws_security_group.backend-sg.id]
	user_data = file("scr/init_mysql.sh")
	
	tags = {
		Environment = "Production"
		Name = "backend"
		Owner = "Federico Cabrera"
		Project = "Endavel"
		ApplicationID = "300622"
	}
}