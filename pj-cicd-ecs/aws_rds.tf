resource "aws_db_instance" "mariadb" {
  allocated_storage = 20 # ストレージ容量 (GB)
  storage_type      = "gp2"
  engine            = "mariadb"
  engine_version    = "10.4"
  instance_class    = "db.t2.micro"
  identifier        = "mariadb-instance"

  # 下記を設定しないと、デフォルトSGが紐づけられてしまう
  vpc_security_group_ids = [aws_security_group.mariadb_sg.id]

  username             = aws_ssm_parameter.psql_user.value
  password             = aws_ssm_parameter.psql_password.value
  parameter_group_name = "default.mariadb10.4"
  db_subnet_group_name = aws_db_subnet_group.mariadb_subnet_group.name # DBインスタンスが配置されるDBサブネットグループ
  skip_final_snapshot  = true                                          # インスタンス削除時にスナップショットを作成しない
}

# サブネットグループ
resource "aws_db_subnet_group" "mariadb_subnet_group" {
  name       = "mariadb-subnet-group-by-tf"
  subnet_ids = [aws_subnet.laravel_subnet_rds1.id, aws_subnet.laravel_subnet_rds2.id]

  tags = {
    Name        = "dbSubnetGroupByTf"
    Environment = "sandbox"
    Source      = "terraform"
    Project     = "pjCicdEcs"
  }
}

resource "aws_subnet" "laravel_subnet_rds1" {
  vpc_id            = aws_vpc.laravel_vpc.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name        = "publicSubnetRds1ByTf"
    Environment = "sandbox"
    Source      = "terraform"
    Project     = "pjCicdEcs"
  }
}

resource "aws_subnet" "laravel_subnet_rds2" {
  vpc_id            = aws_vpc.laravel_vpc.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "ap-northeast-1c"

  tags = {
    Name        = "publicSubnetRds2ByTf"
    Environment = "sandbox"
    Source      = "terraform"
    Project     = "pjCicdEcs"
  }
}

# PostgreSQLのDBを使用したいので命名を変更したい
resource "aws_security_group" "mariadb_sg" {
  name        = "postgredb-sg"
  description = "Security group for RDS instance"
  vpc_id      = aws_vpc.laravel_vpc.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.laravel_ecs_sg.id]
    # security_group_id = aws_db_instance.mariadb.security_group_names[0] # ここにデータベースのセキュリティグループ名を指定する
    # source_security_group_id = aws_security_group.laravel_ecs_sg.id # ここにECS Fargateのセキュリティグループ名を指定する
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "mariadbSgByTf"
    Environment = "sandbox"
    Source      = "terraform"
    Project     = "pjCicdEcs"
  }
}
