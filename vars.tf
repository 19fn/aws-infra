variable "cblock_vpc" {
	type = string
} 

variable "aws_region" {
	type = string
	default = "us-east-2"
}

variable "cblock_public_subnet" {
	type = string
}

variable "cblock_private_subnet" {
	type = string
}

variable "backend_instance" {
	type = string
	default = "t2.micro"
}

variable "bastion_instance" {
	type = string
	default = "t2.micro"
}

variable "frontend_instance" {
	type = string
	default = "t2.micro"
}

variable "key_pair_backend" {
	type = string
}

variable "key_pair_bastion" {
	type = string
}

variable "key_pair_frontend" {
	type = string
}

variable "private_key_location" {
	type = string
}
