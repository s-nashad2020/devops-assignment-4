# IAM user
resource "aws_iam_user" "terraform-user-devops" {
    name = "terraform-user-devops"
}

resource "aws_iam_user_policy_attachment" "admin_policy_attachment" {
  user       = aws_iam_user.terraform-user-devops.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# VPC
resource "aws_vpc" "devops-assignment-4" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "devops-assignment-4"
  }
}

# Public Subnets 
resource "aws_subnet" "cs423-devops-public-1" {
  vpc_id            = aws_vpc.devops-assignment-4.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-2a"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "cs423-devops-public-1"
  }
}

resource "aws_subnet" "cs423-devops-public-2" {
  vpc_id            = aws_vpc.devops-assignment-4.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-2b"
  map_public_ip_on_launch = "true"
  tags = {
    Name = "cs423-devops-public-2"
  }
}


# Private Subnets
resource "aws_subnet" "cs423-devops-private-1" {
  vpc_id                  = aws_vpc.devops-assignment-4.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = false
  tags = {
    Name = "cs423-devops-private-1"
  }
}
resource "aws_subnet" "cs423-devops-private-2" {
  vpc_id                  = aws_vpc.devops-assignment-4.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "us-east-2b"
  map_public_ip_on_launch = false
  tags = {
    Name = "cs423-devops-private-2"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "cs423-devops-igw" {
  tags = {
    Name = "cs423-devops-igw"
  }
  vpc_id = aws_vpc.devops-assignment-4.id
}

# Create VPC Endpoint for S3
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.devops-assignment-4.id
  service_name = "com.amazonaws.us-east-2.s3"
}

# Create a Route Table
resource "aws_route_table" "devops-terraform-rt" {
  vpc_id = aws_vpc.devops-assignment-4.id
  tags = {
    Name = "devops-terraform-rt"
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cs423-devops-igw.id
  }
}

resource "aws_route_table" "devops-rt" {
  vpc_id = aws_vpc.devops-assignment-4.id
  tags = {
    Name = "devops-rt"
  }
  route {
    cidr_block = "0.0.0.0/0"
    vpc_endpoint_id = aws_vpc_endpoint.s3.id
  }
}


# Route Table Association
resource "aws_route_table_association" "devops-terraform-1" {
  subnet_id      = aws_subnet.cs423-devops-public-1.id
  route_table_id = aws_route_table.devops-terraform-rt.id
}

resource "aws_route_table_association" "devops-terraform-2" {
  subnet_id      = aws_subnet.cs423-devops-public-2.id
  route_table_id = aws_route_table.devops-terraform-rt.id
}

resource "aws_route_table_association" "devops-terraform-3" {
  subnet_id      = aws_subnet.cs423-devops-private-1.id
  route_table_id = aws_route_table.devops-rt.id
}
resource "aws_route_table_association" "devops-terraform-4" {
  subnet_id      = aws_subnet.cs423-devops-private-2.id
  route_table_id = aws_route_table.devops-rt.id
}

#security group
resource "aws_security_group" "terraform-devops-security" {
  name        = "terraform-devops-security"
  vpc_id      = aws_vpc.devops-assignment-4.id

  # Allow incoming traffic
  ingress {
    from_port   = 22  # SSH
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80  # HTTP
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow outgoing traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform-devops-security"
  }
}

# create key pair
resource "aws_key_pair" "cs423-assignment4-key" {
key_name = "cs423-assignment4-key"
public_key = tls_private_key.rsa.public_key_openssh
}
resource "tls_private_key" "rsa" {
algorithm = "RSA"
rsa_bits  = 4096
}
resource "local_file" "tf-key" {
content  = tls_private_key.rsa.private_key_pem
filename = "cs423-assignment4-key"
}

# EC2 instances
resource "aws_instance" "Assignment4-EC2-1" {
  instance_type          = "t2.micro"
  ami                    = "ami-05fb0b8c1424f266b" # us-east-2
  key_name               = "cs423-assignment4-key"
  subnet_id              = aws_subnet.cs423-devops-public-1.id
  vpc_security_group_ids = [aws_security_group.terraform-devops-security.id]
  user_data              = file("user_data.sh")

  root_block_device {
    volume_size = 20
  }
  tags = {
    Name = "Assignment4-EC2-1"
  }
}

resource "aws_instance" "Assignment4-EC2-2" {
  ami           = "ami-05fb0b8c1424f266b" # us-east-2
  instance_type = "t2.micro"
  key_name   = "cs423-assignment4-key"
  subnet_id = aws_subnet.cs423-devops-private-1.id
  vpc_security_group_ids = [aws_security_group.terraform-devops-security.id]
  tags = {
    Name = "Assignment4-EC2-2"
  }
}
