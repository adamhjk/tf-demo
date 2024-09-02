terraform {
  cloud {
    organization = "demo_time"
    workspaces {
        name = "demo_time"
    }
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "us-west-2"
}

resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"

    tags = {
        Name = "Project VPC"
    }
}

variable "public_subnet_cidrs" {
    type = list(string)
    description = "Public Subnet CIDR Values"
    default = [ "10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
    type = list(string)
    description = "Private Subnet CIDR values"
    default = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

variable "azs" {
    type = list(string)
    description = "Availability Zones"
    default = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

resource "aws_subnet" "public_subnets" {
    count = length(var.public_subnet_cidrs)
    vpc_id = aws_vpc.main.id
    cidr_block = element(var.public_subnet_cidrs, count.index)
    availability_zone = element(var.azs, count.index)

    tags = {
        Name = "Public Subnet ${count.index + 1}"
    }
}

resource "aws_subnet" "private_subnets" {
    count = length(var.private_subnet_cidrs)
    vpc_id = aws_vpc.main.id
    cidr_block = element(var.private_subnet_cidrs, count.index)
    availability_zone = element(var.azs, count.index)

    tags = {
        Name = "Private Subnet ${count.index + 1}"
    }
}

resource "aws_internet_gateway" "gw" {
    vpc_id = aws_vpc.main.id

    tags = { 
        Name = "Project VPC IG"
    }
}

resource "aws_route_table" "second_rt" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.gw.id
    }

    tags = {
        Name = "2nd route table"
    }
}

resource "aws_route_table_association" "public_subnet_asso" {
    count = length(var.public_subnet_cidrs)
    subnet_id = element(aws_subnet.public_subnets[*].id, count.index)
    route_table_id = aws_route_table.second_rt.id
}

resource "aws_key_pair" "fedora-pair" {
    key_name = "fedora-pair"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDRCT1V+9Ss9P0QwZse4EMhqKvR0SsFuohkp+F20HsFujpuVydvr7+OdWnNgBsk9XVHDvKFLQtfY5hMy8f8NTqnLrZIcMP44vznjs9JvdsIlSvXu++tJn2FgayqnFtqYbjNB8GBamlHT7beBT+LbDeFji4j3RaHaBjScIFgEmkh9Q3FgPpYueRya14t+NFbhD/MxTiY/SSrOXfa5//eP0SaQs9nZjGA3ERX/GthQMp44fV6CznT9H9AVp5heQJKAEbt9pI5j05APeWhmkXHuOeOiYYldZ9uF51woQ7PMotc1CZFZv35DsPVxxZeaqNgS5OmadLkA5fz0h2ehvnksJmuibaPLXD0KLjJr0j63VitNteeTqEnsw6/4TQCXDOy4D7YWetKbpsy0nAj6YdD08KV+InPPd+5HBq6xg5I6MMan0DWi2BgcqfHcqjrbiE9w7SKU3i0Uj72nUVRYDw6huBQFCcK8RIiJSpbdrV6rtK9thyN24su7f2mMAQzX9jaD6rcjcn+nYYWOZGXQmUeO0MqfbzuWyQsrjhlmheiZDrzQaC5PVsgcI6luo3wnv2tf6Hf11JI5dZO6fIHHr16fsmf2iUaNjjJys0cxCIQ6v8mrnONj+ftF1ISt6bgg0y0UyyYuG01JlDyucOV5fvE6+qKg4WQ+nPO6kE5F6NToxGV6w== adam@stalecoffee.org"
}

resource "aws_instance" "fedora" {
    ami = "ami-06b7f026f48cd3c6b"
    instance_type = "t2.micro"
    key_name = aws_key_pair.fedora-pair.key_name
    tags = {
        Name = "Terraform demo"
    }
}