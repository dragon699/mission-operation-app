data "aws_availability_zones" "valid_zones" {
    state = "available"
}

resource "aws_vpc" "satellite_app" {
    cidr_block           = "10.0.0.0/16"

    enable_dns_hostnames = true
    enable_dns_support   = true

    tags = {
      Service            = "satellite_app"
      Description        = "Satellites application VPC"
    }
}

resource "aws_subnet" "satellite_app_database" {
    count             = 2

    vpc_id            = aws_vpc.satellite_app.id
    cidr_block        = var.db_cidrs[count.index]
    availability_zone = data.aws_availability_zones.valid_zones.names[count.index]

    tags = {
      Service         = "satellite_app"
      Description     = "Satellites application public subnet for the (RDS) database"
    }
}

# resource "aws_vpc_endpoint" "satellite_app_s3" {
#     vpc_id = aws_vpc.satellite_app.id

#     service_name = "com.amazonaws.${var.region}.s3"
#     vpc_endpoint_type = "Gateway"

#     tags = {
#       Service     = "satellite_app"
#       Description = "Satellites application VPC endpoint for S3"
#     }
# }

# resource "aws_vpc_endpoint" "satellite_app_rds" {
#     vpc_id = aws_vpc.satellite_app.id

#     service_name = "com.amazonaws.${var.region}.rds"
#     vpc_endpoint_type = "Interface"
#     private_dns_enabled = true

#     subnet_ids = aws_subnet.satellite_app_database[*].id
#     security_group_ids = [aws_security_group.satellite_app_database.id]

#     tags = {
#       Service     = "satellite_app"
#       Description = "Satellites application VPC endpoint for RDS"
#     }
# }

resource "aws_internet_gateway" "satellite_app" {
  vpc_id = aws_vpc.satellite_app.id

  tags = {
    Service = "satellite_app"
    Description = "Satellites application Internet Gateway - for enabling internet traffic for the Backend API application"
  }
}

resource "aws_route_table" "satellite_app" {
  vpc_id = aws_vpc.satellite_app.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.satellite_app.id
  }

  tags = {
    Service = "satellite_app"
    Description = "Satellites application route table - for enabling internet traffic for the Backend API application through the Internet Gateway"
  }
}

resource "aws_route_table_association" "satellite_app" {
  count = 2

  subnet_id = aws_subnet.satellite_app_database[count.index].id
  route_table_id = aws_route_table.satellite_app.id
}

resource "aws_db_subnet_group" "satellite_app" {
    name              = "satellite-app"
    subnet_ids        = aws_subnet.satellite_app_database[*].id
}
