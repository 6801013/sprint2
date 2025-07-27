# -------------------------
# Provider
# -------------------------
provider "aws" {
  region = "ap-northeast-1"
}

# -------------------------
# Variables
# -------------------------
variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
  default     = "ami-0bc8f29a8fc3184aa"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/21"
}

variable "web_cidr" {
  description = "CIDR block for web subnet"
  type        = string
  default     = "10.0.0.0/24"
}

variable "api_cidr" {
  description = "CIDR block for api subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "db_cidr_1" {
  description = "CIDR block for db subnet 1"
  type        = string
  default     = "10.0.2.0/24"
}

variable "db_cidr_2" {
  description = "CIDR block for db subnet 2"
  type        = string
  default     = "10.0.3.0/24"
}

variable "myip" {
  description = "Your IP address for restricted access"
  type        = string
  default     = "0.0.0.0/0"
}

variable "key_name" {
  description = "Key pair name for EC2 instances"
  type        = string
  default     = "test-ec2-key"
}

variable "web_name" {
  description = "Name prefix for web resources"
  type        = string
  default     = "web"
}

variable "api_name" {
  description = "Name prefix for api resources"
  type        = string
  default     = "api"
}

variable "db_name" {
  description = "Name prefix for db resources"
  type        = string
  default     = "db"
}

variable "main_name" {
  description = "Name prefix for main resources"
  type        = string
  default     = "main"
}

variable "iam_users" {
  description = "IAM users and their group memberships"
  type = map(object({
    groups = list(string)
  }))
  default = {
    "test-taro"   = { groups = ["user-management-group"] },
    "test-jiro"   = { groups = ["server-management-group"] },
    "test-saburo" = { groups = ["database-management-group"] },
    "test-shiro"  = { groups = ["server-management-group", "database-management-group"] }
  }
}


# -------------------------
# VPC and Networking
# -------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.main_name}-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.main_name}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.main_name}-public-rt"
  }
}

resource "aws_subnet" "web_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.web_cidr
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.web_name}-subnet"
  }
}

resource "aws_subnet" "api_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.api_cidr
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.api_name}-subnet"
  }
}

resource "aws_subnet" "db_subnet_1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.db_cidr_1
  availability_zone = "ap-northeast-1a" # 異なるAZにする
  tags = {
    Name = "${var.db_name}-subnet-1"
  }
}

resource "aws_subnet" "db_subnet_2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.db_cidr_2
  availability_zone = "ap-northeast-1c" # 異なるAZにする
  tags = {
    Name = "${var.db_name}-subnet-2"
  }
}

resource "aws_route_table_association" "web_assoc" {
  subnet_id      = aws_subnet.web_subnet.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "api_assoc" {
  subnet_id      = aws_subnet.api_subnet.id
  route_table_id = aws_route_table.public.id
}

# -------------------------
# Security Groups
# -------------------------
resource "aws_security_group" "web_sg" {
  name        = "${var.web_name}-sg"
  description = "Allow HTTP and SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.web_name}-sg"
  }
}

resource "aws_security_group" "api_sg" {
  name        = "${var.api_name}-sg"
  description = "Allow HTTP and SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.api_name}-sg"
  }
}

resource "aws_security_group" "db_sg" {
  name        = "${var.db_name}-sg"
  description = "Allow MySQL from API subnet"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.api_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.db_name}-sg"
  }
}

# -------------------------
# EC2 Instances
# -------------------------
resource "aws_instance" "web_ec2" {
  ami           = var.ami_id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.web_subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name      = var.key_name
  tags = {
    Name = "${var.web_name}-server"
  }
}

resource "aws_instance" "api_ec2" {
  ami           = var.ami_id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.api_subnet.id
  vpc_security_group_ids = [aws_security_group.api_sg.id]
  key_name      = var.key_name
  tags = {
    Name = "${var.api_name}-server"
  }
}

# -------------------------
# RDS
# -------------------------
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${var.db_name}-subnet-group"
  subnet_ids = [aws_subnet.db_subnet_1.id, aws_subnet.db_subnet_2.id]
  tags = {
    Name = "${var.db_name}-subnet-group"
  }
}

resource "aws_db_instance" "mysql" {
  identifier             = "${var.db_name}-server"
  engine                 = "mysql"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  username               = "admin"
  password               = "test1234"
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  tags = {
    Name = "${var.db_name}-rds"
  }
}

# -------------------------
# IAM Groups
# -------------------------
resource "aws_iam_group" "server_mgmt" {
  name = "server-management-group"
}

resource "aws_iam_group" "database_mgmt" {
  name = "database-management-group"
}

resource "aws_iam_group" "user_mgmt" {
  name = "user-management-group"
}

resource "aws_iam_user" "users" {
  for_each = var.iam_users
  name     = each.key
}

# -------------------------
# IAM User
# -------------------------
resource "aws_iam_user_group_membership" "memberships" {
  for_each = var.iam_users
  user     = aws_iam_user.users[each.key].name
  groups   = [
    for group in each.value.groups :
    group == "server-management-group" ? aws_iam_group.server_mgmt.name :
    group == "database-management-group" ? aws_iam_group.database_mgmt.name :
    aws_iam_group.user_mgmt.name
  ]
}