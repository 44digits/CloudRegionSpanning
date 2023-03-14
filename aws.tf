##########################################################
# AWS resources
#
#   AWS Instance will be the client for testing
#
##########################################################


##########################################################
# Data
##########################################################

data "aws_ssm_parameter" "ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

data "aws_availability_zones" "available" {}


##########################################################
# Resources
##########################################################

resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/24"
  enable_dns_hostnames = true
  tags = merge(
    {
      Name = "${local.name_prefix}_vpc",
    },
    local.common_tags
  )
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = merge(
    {
      Name = "${local.name_prefix}_igw",
    },
    local.common_tags
  )
}

resource "aws_subnet" "subnet" {
  cidr_block              = "10.0.0.0/24"
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]
  tags                    = local.common_tags
}

resource "aws_route_table" "rtb" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = merge(
    {
      Name = "${local.name_prefix}_rtb",
    },
    local.common_tags
  )
}

resource "aws_route_table_association" "rtb-subnet" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.rtb.id
}

resource "aws_security_group" "sg" {
  name   = "${local.name_prefix}_sg"
  vpc_id = aws_vpc.vpc.id

  # HTTP access from VPC
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name = "${local.name_prefix}_sg",
    },
    local.common_tags
  )
}

resource "aws_instance" "aws-instance" {
  ami                    = nonsensitive(data.aws_ssm_parameter.ami.value)
  instance_type          = var.instance_type
  key_name               = "k3"
  subnet_id              = aws_subnet.subnet.id
  vpc_security_group_ids = [aws_security_group.sg.id]
  user_data = <<EOF
    #cloud-config
    ${jsonencode({
  write_files = [{
    path        = "/usr/local/bin/networktest"
    permissions = "0755"
    owner       = "root:root"
    encoding    = "b64"
    content     = filebase64("${path.module}/networktest")
}, ] })}
EOF

tags = merge(
  {
    Name = "${local.name_prefix}_client",
  },
  local.common_tags
)
}

