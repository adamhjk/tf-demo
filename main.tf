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

resource "aws_key_pair" "fedora-keypair" {
    key_name = "fedora-keypair"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDTx9n3Mt+wgBFCsRFmlgtPAfT1h1/NIZqLTwxTwXf/o335BgKUcUWd3+qZjf9d5lXT603y9I9nnIfDt3evldnlDwHVEHHKUplSxXradecjspDbdSFQ3wr6iTyMWpQhYim0BvqWFM2bchCGl3HzBrXIX0/R1kU9srN0Qe4c0UDCVCLNQpl9qefeEOsPOEBdnsUMQ5E9SSMjAAXY6V+RsKfAsD3kwPpOuixibDZN2DwLr7Y8iiSOwY9dqMRR7HGhGHJkMUO/PpQaksNm+AEqUuFzDbmDaSjyjfLM78p8nqYPqneSBOkX9cP8E6gMKv1QTas+CWa0eB+C556l9yHXnUYBpHFjGdKFG1PfFxF4cqxrc2c0Ydjz792EtmA2eXx1TUGml1hIdYyEftBlJV6tshJ1E0edCqlNDPpgDGb8oWgniU6lfJ7+kM+U2sSkNlk3oeC1MSHXT3JJpwlu3hAekRsHinFkMm6MWEnsxe+saX11O2/0D3th58/1pLXtjoSEYSPH3WNe/fKLUfCejF7/J69cnJ+A5FLQuepes3Bh6BmTwxjr/cSsSKrvZw2p4tFuFSegkDKOR0Yq3DNyLb7vttF1DBWmoxcxexUuI+WiPHcvlKLSaYpVQ8xIKpLfpglK2RXpZJRVUotRxrfZitbHdjQ1MHFySQxgh4gC/4rsg8nDVw== adam@stalecoffee.org"
}

resource "aws_instance" "fedora" {
    ami = "ami-06b7f026f48cd3c6b"
    instance_type = "t2.micro"
    key_name = aws_key_pair.fedora-keypair.key_name
    tags = {
        Name = "Terraform demo"
    }
}