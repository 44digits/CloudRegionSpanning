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

data "template_file" "client_tpl" {
  template = file("${path.module}/templates/client.tpl")
  vars = {
    server_publicip  = "${module.azure-server.public_ip}"
    proxy_publicip   = "${module.azure-proxy.public_ip}"
    networktest_file = filebase64("${path.module}/utilities/networktest")
  }
}

data "template_cloudinit_config" "config_client" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = data.template_file.client_tpl.rendered
  }
}


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

resource "aws_key_pair" "awsclient_key_pair" {
  key_name   = "client-key-pair"
  public_key = tls_private_key.awskey_rsa.public_key_openssh
}

resource "tls_private_key" "awskey_rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "awsclient_key" {
  content         = tls_private_key.awskey_rsa.private_key_pem
  filename        = "${path.module}/key/aws_key.pem"
  file_permission = "0600"
}

resource "aws_instance" "aws-instance" {
  ami                    = nonsensitive(data.aws_ssm_parameter.ami.value)
  instance_type          = var.aws_instance_type
  key_name               = "client-key-pair"
  subnet_id              = aws_subnet.subnet.id
  vpc_security_group_ids = [aws_security_group.sg.id]
  user_data_base64       = data.template_cloudinit_config.config_client.rendered

  tags = merge(
    {
      Name = "${local.name_prefix}_client",
    },
    local.common_tags
  )
}

