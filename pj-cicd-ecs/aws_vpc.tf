# VPCの作成
resource "aws_vpc" "laravel_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name        = "vpcByTf"
    Environment = "sandbox"
    Source      = "terraform"
    Project     = "pjCicdEcs"
  }
}

# パブリックサブネットの作成
resource "aws_subnet" "laravel_subnet" {
  vpc_id                  = aws_vpc.laravel_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = true

  tags = {
    Name        = "publicSubnetByTf"
    Environment = "sandbox"
    Source      = "terraform"
    Project     = "pjCicdEcs"
  }
}

# ELB設定の際に複数のサブネットが必要なため
resource "aws_subnet" "laravel_subnet2" {
  vpc_id                  = aws_vpc.laravel_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-northeast-1c"
  map_public_ip_on_launch = true

  tags = {
    Name        = "publicSubnet2ByTf"
    Environment = "sandbox"
    Source      = "terraform"
    Project     = "pjCicdEcs"
  }
}

# ELB設定の際に複数のサブネットが必要なため
resource "aws_subnet" "laravel_subnet3" {
  vpc_id                  = aws_vpc.laravel_vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "ap-northeast-1d"
  map_public_ip_on_launch = true

  tags = {
    Name        = "publicSubnet3ByTf"
    Environment = "sandbox"
    Source      = "terraform"
    Project     = "pjCicdEcs"
  }
}

# インターネットゲートウェイの作成
resource "aws_internet_gateway" "laravel_igw" {
  vpc_id = aws_vpc.laravel_vpc.id

  tags = {
    Name        = "myIgwByTf"
    Environment = "sandbox"
    Source      = "terraform"
    Project     = "pjCicdEcs"
  }
}

# ルートテーブルの作成
resource "aws_route_table" "laravel_rtb" {
  vpc_id = aws_vpc.laravel_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.laravel_igw.id
  }

  tags = {
    Name        = "publicRouteTableByTf"
    Environment = "sandbox"
    Source      = "terraform"
    Project     = "pjCicdEcs"
  }
}

# サブネットにルートテーブルを紐づけ
resource "aws_route_table_association" "laravel_rt_assoc" {
  subnet_id      = aws_subnet.laravel_subnet.id
  route_table_id = aws_route_table.laravel_rtb.id
}

# サブネットにルートテーブルを紐づけ2
resource "aws_route_table_association" "laravel_rt_assoc2" {
  subnet_id      = aws_subnet.laravel_subnet2.id
  route_table_id = aws_route_table.laravel_rtb.id
}
