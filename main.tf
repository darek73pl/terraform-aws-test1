
data "aws_availability_zones" "azs" {
  state = "available"
}

data "aws_ami" "linux_ami" {
    most_recent = true
    owners      = ["amazon"]
  
    filter {
        name   = "name"
        values = ["amzn2-ami-hvm*"]
    }

    filter {
        name   = "root-device-type"
        values = ["ebs"]
    }

    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }
}

#######################################################################

# Create a VPC
resource "aws_vpc" "test1" {
    cidr_block           = var.test_vcp_cidr
    enable_dns_hostnames = true
    enable_dns_support   = true

    tags = {
        Name = "test1-vpc"
    }
}

resource "aws_subnet" "test1-subnet" {
  count                   = length(var.test_subnets)

  vpc_id                  = aws_vpc.test1.id
  cidr_block              = var.test_subnets[count.index]
  availability_zone       = data.aws_availability_zones.azs.names[0]
  map_public_ip_on_launch = var.test_subnets_public_ips[count.index] 

  tags = {
    Name = var.test_subnet_names[count.index]
  }
}

resource "aws_internet_gateway" "test1_igw" {
  vpc_id = aws_vpc.test1.id
  
  tags = {
    Name = "test1-igw"
  }
}

resource "aws_route_table" "public_rt" {
    vpc_id = aws_vpc.test1.id
    
    tags = {
        Name = "public-rt"
    }
}

resource "aws_route_table" "private_rt" {
    vpc_id = aws_vpc.test1.id
    
    tags = {
        Name = "private-rt"
    }
}

resource "aws_route" "traffic_outside" {
    route_table_id         = aws_route_table.public_rt.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id             = aws_internet_gateway.test1_igw.id
}

resource "aws_route_table_association" "rt_association" {
    count          = length(var.test_subnets)

    subnet_id      = aws_subnet.test1-subnet[count.index].id
    route_table_id = var.test_subnets_public_ips[count.index] == true ? aws_route_table.public_rt.id : aws_route_table.private_rt.id
}

resource "aws_security_group" "private_sg" {
    name        = "private-sg"
    description = "Allow SSH only from jumpbox"
    vpc_id      = aws_vpc.test1.id
}

resource "aws_security_group" "public_sg" {
    name        = "public-sg"
    description = "Allow SSH from outside"
    vpc_id      = aws_vpc.test1.id
}

resource "aws_security_group_rule" "allow_ssh_from_anywhere" {
    type              = "ingress"
    from_port         = 22
    to_port           = 22
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
    security_group_id = aws_security_group.public_sg.id
}

resource "aws_security_group_rule" "allow_ssh_from_public_subnet" {
    type                     = "ingress"
    from_port                = 22
    to_port                  = 22
    protocol                 = "tcp"
    source_security_group_id = aws_security_group.public_sg.id
    security_group_id        = aws_security_group.private_sg.id
}

resource "aws_security_group_rule" "allow_all_to_outside" {
    count             = 2
    
    type              = "egress"
    from_port         = 0
    to_port           = 0
    protocol          = "-1"
    cidr_blocks       = ["0.0.0.0/0"]
    security_group_id = count.index == 0 ? aws_security_group.public_sg.id : aws_security_group.private_sg.id
}

resource "aws_instance" "ec2_instance" {
    count                  = length(var.test_subnets)
    
    ami                    = data.aws_ami.linux_ami.id
    instance_type          = "t2.micro"
    availability_zone      = data.aws_availability_zones.azs.names[0]
    subnet_id              = aws_subnet.test1-subnet[count.index].id
    vpc_security_group_ids = var.test_subnets_public_ips[count.index] == true ? [aws_security_group.public_sg.id] : [aws_security_group.private_sg.id]
    key_name               = "SSH-key"
    tags = {
        Name = "${var.test_subnet_names[count.index]}-instance"
  }
}
