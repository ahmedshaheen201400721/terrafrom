provider "aws"{
  region     = "us-east-1"
}

variable "cidr_block" {
  description = "your cidr block"
  type = list(object({
    range:string,
    name:string 
  }))
}
resource "aws_vpc" "vpc-test" {
  cidr_block = var.cidr_block[0].range
  tags ={
    Name:"dev-vpc"
    vpc-enf:"dev"
  }
}
variable "avail_zone" {}
resource "aws_subnet" "subnet-test" {
  vpc_id = aws_vpc.vpc-test.id
  cidr_block= "10.0.0.0/24"
  availability_zone = var.avail_zone
   tags ={
    Name:"dev-subnet"
  }
}


data "aws_vpc"  "existing_vpc"{
  default = true
}
resource "aws_subnet" "subnet-defualt" {
  vpc_id = data.aws_vpc.existing_vpc.id
  cidr_block= "172.31.96.0/20"
  availability_zone = "us-east-1a"
   tags ={
    Name:"default-subnet"
  }
}

output "vpc-new-id" {
  value = aws_vpc.vpc-test.id
}


output "vpc-new-subnet" {
  value = aws_subnet.subnet-test.id
}