variable "aws_region" {
  description = "AWS region for hosting our your network"
  default = "us-east-1"
}
variable "access_key"{
description = "AWS Access Key"
default = "access-key"
}

variable "secret_key"{
description = "AWS Secret Key"
default = "secret_key"
}
variable "vpc_name" {
  description = "AWS region for hosting our your network"
  default = "test_vpc"
}
variable "vpc_cidr" {
    description = "CIDR for the whole VPC"
    default = "10.0.0.0/16"
}
variable "public_subnet_cidr" {
    description = "CIDR for the Public Subnet"
    default = "10.0"
}
variable "private_subnet_cidr" {
    description = "CIDR for the Private Subnet"
    default = "10.0"
}