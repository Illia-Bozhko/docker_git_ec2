variable aws_access_key_id {
    description = "aws_access_key_id"
}

variable secret_access_key_id {
    description = "secret_access_key_id"
}


provider "aws" {
    region = "ap-south-1"
    access_key = var.aws_access_key_id
    secret_key = var.secret_access_key_id
}

#vpc
resource "aws_vpc" "prod-vpc" {
  cidr_block = "10.0.0.0/16"
}

#internet gateway
resource "aws_internet_gateway" "gw" {
    vpc_id = aws_vpc.prod-vpc.id
}

#route table
resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "prod"
  }
}

#subnet
resource "aws_subnet" "subnet-1" {
    vpc_id = aws_vpc.prod-vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "ap-south-1a"
}

#associate route table and subnet
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.prod-route-table.id
}

#security group
resource "aws_security_group" "allow_web" {
  name        = "allow_web"
  description = "Allow WEB inbound traffic"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
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

  tags = {
    Name = "allow_tls"
  }
}

#network interface
resource "aws_network_interface" "server_nic" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]
}

#elastic ip
resource "aws_eip" "elastic_ip" {
  network_interface         = aws_network_interface.server_nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.gw, aws_instance.ec2-instance]
}

#instance
resource "aws_instance" "ec2-instance" {
    ami = "ami-072ec8f4ea4a6f2cf"
    instance_type = "t2.micro"
    availability_zone = "ap-south-1a"

    network_interface {
      device_index = 0
      network_interface_id = aws_network_interface.server_nic.id
    }
    
    user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install git -y

    sudo yum install -y yum-utils device-mapper-persistent-data lvm2
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    sudo yum -y install docker
    sudo systemctl start docker && sudo systemctl enable docker
    sudo usermod -aG docker ec2-user
    EOF
}