#################
# Network infra #
#################

resource "aws_vpc" "main" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

####################
# Internet Gateway #
####################

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${local.prefix}-main"
  }
}

##################################################
# Public subnets for load balacner public access #
##################################################

// az-a
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.1.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_region.current.name}a"
  tags = {
    Name = "${local.prefix}-public-a" // a for az (a or b)
  }
}

resource "aws_route_table" "public_a" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${local.prefix}-public-a"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_a.id
}

resource "aws_route" "public_internet_access_a" {
  route_table_id         = aws_route_table.public_a.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

// az-b
resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.1.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_region.current.name}b"
  tags = {
    Name = "${local.prefix}-public-b" // b for az (a or b)
  }
}

resource "aws_route_table" "public_b" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${local.prefix}-public-b"
  }
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public_b.id
}

resource "aws_route" "public_internet_access_b" {
  route_table_id         = aws_route_table.public_b.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

/* 
  Summary:
 1. The VPC serves as the foundational network layer.
 2. The Internet Gateway connects the VPC to the internet.
 3. Public Subnets are created within the VPC, each associated with a specific AZ, and are configured to provide public IPs to instances.
 4. Route Tables are associated with each subnet, directing internet-bound traffic through the Internet Gateway.
*/

############################################
# Private subnets for internal access only #
############################################

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.1.10.0/24"
  availability_zone = "${data.aws_region.current.name}a"

  tags = {
    Name = "${local.prefix}-private-a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.1.11.0/24"
  availability_zone = "${data.aws_region.current.name}b"

  tags = {
    Name = "${local.prefix}-private-b"
  }
}

#######################################################
# VPC Enpoints for ECS, CloudWatch and System Manager #
#######################################################

/* 
  Vpc enpoint allow to give the resources that run into
  private netwrks access to another aws resources.

  Is it necessary to create a security group that provide
  access to vpc endpoint from the resources in the subnet.
*/

resource "aws_security_group" "endpoint_access" {
  description = "Access to endpoints"
  name        = "${local.prefix}-endpoint-access"
  vpc_id      = aws_vpc.main.id

  ingress { // give access to anywher in the vpc to all addresses
    cidr_blocks = [aws_vpc.main.cidr_block]
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"

  }
}

// Necessary endpoints so that ECR service being psible
// Connection to ECR from ECS

resource "aws_vpc_endpoint" "ecr" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  security_group_ids = [
    aws_security_group.endpoint_access.id
  ]

  tags = {
    Name = "${local.prefix}-ecr-endpoint"
  }
}
resource "aws_vpc_endpoint" "dkr" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  security_group_ids = [
    aws_security_group.endpoint_access.id
  ]

  tags = {
    Name = "${local.prefix}-dkr-endpoint"
  }
}

resource "aws_vpc_endpoint" "cloudwatch_logs" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.logs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  security_group_ids = [
    aws_security_group.endpoint_access.id
  ]

  tags = {
    Name = "${local.prefix}-cloudwatch-endpoint"
  }
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  security_group_ids = [
    aws_security_group.endpoint_access.id
  ]

  tags = {
    Name = "${local.prefix}-ssmmessages-endpoint"
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [
    aws_vpc.main.default_route_table_id
  ]
  tags = {
    Name = "${local.prefix}-s3-endpoint"
  }
}

