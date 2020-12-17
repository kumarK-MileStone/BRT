data "aws_availability_zones" "available" {}
# Vpc resource
resource "aws_vpc" "Vpc" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  tags = {
    Name = "${var.vpc_name}"
  }
}

# Internet gateway for the public subnets
resource "aws_internet_gateway" "myInternetGateway" {
  vpc_id = "${aws_vpc.Vpc.id}"

  tags = {
    Name = "myInternetGateway"
  }
}

# Subnet (public)
resource "aws_subnet" "public_subnet" {
  count                   = "${length(data.aws_availability_zones.available.names)}"
  vpc_id                  = "${aws_vpc.Vpc.id}"
  cidr_block              = "${var.public_subnet_cidr}.${10+count.index}.0/24"
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
  map_public_ip_on_launch = false

  tags = {
    Name = "PublicSubnet"
  }
}

# Subnet (private)
resource "aws_subnet" "private_subnet" {
  count                   = "${length(data.aws_availability_zones.available.names)}"
  vpc_id                  = "${aws_vpc.Vpc.id}"
  cidr_block              = "${var.private_subnet_cidr}.${20+count.index}.0/24"
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
  map_public_ip_on_launch = false

  tags = {
    Name = "PrivateSubnet"
  }
}

# Routing table for public subnets
resource "aws_route_table" "rtblPublic" {
  vpc_id = "${aws_vpc.Vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.myInternetGateway.id}"
  }

  tags = {
    Name = "rtblPublic"
  }
}

resource "aws_route_table_association" "route" {
  count          = "${length(data.aws_availability_zones.available.names)}"
  subnet_id      = "${element(aws_subnet.public_subnet.*.id, count.index)}"
  route_table_id = "${aws_route_table.rtblPublic.id}"
}

# Elastic IP for NAT gateway
resource "aws_eip" "nat" {
  vpc = true
}

# NAT Gateway
resource "aws_nat_gateway" "nat-gw" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id     = "${element(aws_subnet.private_subnet.*.id, 1)}"
  depends_on    = ["aws_internet_gateway.myInternetGateway"]
}

# Routing table for private subnets
resource "aws_route_table" "rtblPrivate" {
  vpc_id = "${aws_vpc.Vpc.id}"

  route  {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.nat-gw.id}"
  }

  tags = {
    Name = "rtblPrivate"
  }
}

resource "aws_route_table_association" "private_route" {
  count          = "${length(data.aws_availability_zones.available.names)}"
  subnet_id      = "${element(aws_subnet.private_subnet.*.id, count.index)}"
  route_table_id = "${aws_route_table.rtblPrivate.id}"
}
resource "aws_flow_log" "vpc_flow_log" {
  iam_role_arn    = aws_iam_role.vpc_role.arn
  log_destination = aws_cloudwatch_log_group.vpc_log_group.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.Vpc.id
}

resource "aws_cloudwatch_log_group" "vpc_log_group" {
  name = "${var.vpc_name}_log_group"
}

resource "aws_iam_role" "vpc_role" {
  name = "${var.vpc_name}_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "vpc_role_policy" {
  name = "${var.vpc_name}_role_policy"
  role = aws_iam_role.vpc_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}
