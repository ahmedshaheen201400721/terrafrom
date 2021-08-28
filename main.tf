provider "aws"{
  region     = "us-east-1"
}

variable "vpc_cidr_block" {}
variable "subnet_cidr_block" {}
variable "avail_zone" {}
variable "env" {}
variable "ip" {}
variable "instance_type" {}
variable "public_key" {}


resource "aws_vpc" "vpc-test" {
  cidr_block = var.vpc_cidr_block
  tags={
    Name:"vpc-${var.env}"
  }
}

resource "aws_subnet" "subnet-test" {
  vpc_id = aws_vpc.vpc-test.id
  cidr_block= var.subnet_cidr_block
  availability_zone = var.avail_zone
  tags ={
    Name:"subnet-${var.env}"
  }
}

# create internet geteway
resource "aws_internet_gateway" "myapp_igw" {
  vpc_id = aws_vpc.vpc-test.id
  tags = {
    Name:"internet_gateway-${var.env}"
  }
}
# default route table
resource "aws_default_route_table" "default-rtb" {
  default_route_table_id = aws_vpc.vpc-test.default_route_table_id
   route {
     cidr_block = "0.0.0.0/0"
     gateway_id = aws_internet_gateway.myapp_igw.id
   }
    tags = {
    Name:"default_route_table-${var.env}"
  }
}


# # create routing table to hforward to internet gateway
#  resource "aws_route_table" "myapp-route-table" {
#    vpc_id = aws_vpc.vpc-test.id

#    route {
#      cidr_block = "0.0.0.0/0"
#      gateway_id = aws_internet_gateway.myapp_igw.id
#    }
#     tags = {
#     Name:"route_table-${var.env}"
#   }
#  }
# # associate subnet to route table
#  resource "aws_route_table_association" "a-rtb-subnet" {
#    subnet_id = aws_subnet.subnet-test.id
#    route_table_id = aws_route_table.myapp-route-table.id
#  }


# # create security group
# resource "aws_security_group" "myapp-SG" {
#   name = "myapp-SG"
#   vpc_id = aws_vpc.vpc-test.id
#    tags = {
#     Name:"SG-${var.env}"
#   }

#   ingress {
#       from_port=22
#       to_port = 22
#       protocol = "tcp"
#       cidr_blocks = [var.ip]
#   }

#    ingress {
#       from_port=8080
#       to_port = 8080
#       protocol = "tcp"
#       cidr_blocks = ["0.0.0.0/0"]
#   }

#     egress  {
#       from_port = 0
#       to_port = 0
#       protocol = "-1"
#       cidr_blocks = ["0.0.0.0/0"]

#     }

#   }

resource "aws_default_security_group" "default_SG" {
  vpc_id = aws_vpc.vpc-test.id
   tags = {
    Name:"default-SG-${var.env}"
  }

  ingress {
      from_port=22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = [var.ip]
  }

   ingress {
      from_port=8080
      to_port = 8080
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

    egress  {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]

    }
  
}


data "aws_ami" "latest_image" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}

output "image_name" {
  value = data.aws_ami.latest_image.id
}
resource "aws_key_pair" "key-pair" {
  key_name = "server-key"
  public_key = file(var.public_key)
}
resource "aws_instance" "myapp-server" {
  ami = data.aws_ami.latest_image.id
  instance_type = var.instance_type
  subnet_id = aws_subnet.subnet-test.id
  vpc_security_group_ids = [ aws_default_security_group.default_SG.id ]
  associate_public_ip_address = true
  key_name = aws_key_pair.key-pair.key_name
  user_data = file("entry_script.sh")
 
  tags = {
    "Name" = "myapp_instance"
  }
 
}

output "ip" {
  value = aws_instance.myapp-server.public_ip
}