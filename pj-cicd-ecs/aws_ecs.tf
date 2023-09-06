# ECR リポジトリ
resource "aws_ecr_repository" "laravel_repo" {
  name                 = "laravel-app-repo"
  image_tag_mutability = "MUTABLE" # MUTABLEなら、同じタグでのpushがOK
}

# ECSクラスタ
resource "aws_ecs_cluster" "laravel_cluster" {
  name = "laravel-cluster-by-tf"

  # 下記は必要かがわからない
  # setting {
  #   name  = "containerInsights"
  #   value = "enabled"
  # }
}

# ECSサービス
resource "aws_ecs_service" "laravel_service" {
  name                              = "laravel-service-by-tf"
  cluster                           = aws_ecs_cluster.laravel_cluster.id
  task_definition                   = aws_ecs_task_definition.laravel_task_def.arn
  launch_type                       = "FARGATE"
  desired_count                     = 1   # タスク実行数
  health_check_grace_period_seconds = 300 # ヘルスチェックの猶予時間 (秒)

  network_configuration {
    subnets         = [aws_subnet.laravel_subnet.id, aws_subnet.laravel_subnet2.id]
    security_groups = [aws_security_group.laravel_ecs_sg.id] # ECS用のセキュリティグループを指定

    # ALBとの連携設定
    assign_public_ip = true
  }

  # ALBとの連携設定
  load_balancer {
    target_group_arn = aws_lb_target_group.laravel_target_group.arn
    container_name   = "laravel-app-container-by-tf"
    container_port   = 80
  }

  tags = {
    Name        = "ecsServiceByTf"
    Environment = "sandbox"
    Source      = "terraform"
    Project     = "pjCicdEcs"
  }
}

# ECS Fargate用のセキュリティグループを作成
## ECSサービスとECSタスクのどちらにも適用可能。ECSサービスなら、それに所属するECSタスク全てに一律のルールの適用が可能
resource "aws_security_group" "laravel_ecs_sg" {
  # ランダムに設定
  name_prefix = "ecs-fargate-sg-"
  # description = "Security group for ECS Fargate Service tasks"
  vpc_id = aws_vpc.laravel_vpc.id

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    # ALBのSGのみを指定したい
    security_groups = [aws_security_group.laravel_alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "laravelEcsSgByTf"
    Environment = "sandbox"
    Source      = "terraform"
    Project     = "pjCicdEcs"
  }
}

# ECS Fargateタスク定義
resource "aws_ecs_task_definition" "laravel_task_def" {
  family                   = "laravel-task-by-tf"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.laravel_ecs_execution_role.arn
  task_role_arn            = aws_iam_role.laravel_ecs_task_role.arn
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      name   = "laravel-app-container-by-tf"
      image  = "${aws_ecr_repository.laravel_repo.repository_url}:latest"
      memory = 512
      portMappings = [{
        containerPort = 80,
        hostPort      = 80
      }]
      log_configuration = {
        log_driver = "awslogs"
        options = {
          "awslogs-group"         = "example-logs"
          "awslogs-region"        = "ap-northeast-1"
          "awslogs-stream-prefix" = "example-container"
        }
      },
      environment = [
        {
          name  = "DB_CONNECTION",
          value = "psql"
        },
        {
          name  = "DB_HOST",
          value = "dummy"
          # valueFrom = aws_ssm_parameter.db_endpoint_param.arn
          # valueFrom = aws_ssm_parameter.db_endpoint_param.name
          # value = aws_ssm_parameter.psql_db_endpoint.value
          # 下記は、RDSか、DB用のコンテナかでエンドポイントが変化するため、そのパラメータストアを画面上から手動で変更する
          # value = aws_ssm_parameter.db_endpoint_param.value
        },
        {
          name  = "DB_PORT",
          value = "5432"
        },
        {
          name  = "DB_DATABASE",
          value = aws_ssm_parameter.psql_database.value
          # valueFrom = aws_ssm_parameter.psql_database.arn
          # valueFrom = aws_ssm_parameter.psql_database.name
        },
        {
          name  = "DB_USERNAME",
          value = aws_ssm_parameter.psql_user.value
          # valueFrom = aws_ssm_parameter.psql_user.arn
          # valueFrom = aws_ssm_parameter.psql_user.name
        },
        {
          name  = "DB_PASSWORD",
          value = aws_ssm_parameter.psql_password.value
          # valueFrom = aws_ssm_parameter.psql_password.arn
          # valueFrom = aws_ssm_parameter.psql_password.name
        }
      ]
    },
  ])

  tags = {
    Name        = "ecsTaskDefByTf"
    Environment = "sandbox"
    Source      = "terraform"
    Project     = "pjCicdEcs"
  }
}

# ECS Fargate自体が実行される際に使用されるロール。ECSサービスやCloudWatch Logsなどのリソースにアクセス
resource "aws_iam_role" "laravel_ecs_execution_role" {
  name = "laravel_ecs_task_execution_role_by_tf"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

# IAMロールにCloudWatchFullAccess IAMポリシーをアタッチ
resource "aws_iam_policy_attachment" "attach_cloudwatch_logs_policy" {
  name       = "attach_cloudwatch_logs_policy_by_tf"
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
  roles      = [aws_iam_role.laravel_ecs_execution_role.name, aws_iam_role.laravel_ecs_task_role.name]
}

# ECSタスクのIAMロールに、ECRアクセスのIAMポリシーを付与
resource "aws_iam_policy_attachment" "attach_ecr_full_access" {
  name       = "attach-ecr-full-access-by-tf"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
  roles      = [aws_iam_role.laravel_ecs_execution_role.name, aws_iam_role.laravel_ecs_task_role.name]
}

# 他のAWSサービスと対話するために使用されるIAMロール（ECSタスク用のIAMロール）
resource "aws_iam_role" "laravel_ecs_task_role" {
  name = "laravel_ecs_task_role_by_tf"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

# ECSフルアクセス
resource "aws_iam_policy_attachment" "attach_ecs_task" {
  name       = "attach-ecs-exec-task-by-tf"
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
  roles      = [aws_iam_role.laravel_ecs_task_role.name]
}

# ELBフルアクセス
# 実行用ロールに付与するべき？
resource "aws_iam_policy_attachment" "attach_alb_to_ecs_task" {
  name       = "attach-ecs-exec-task-by-tf"
  policy_arn = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
  roles      = [aws_iam_role.laravel_ecs_task_role.name]
  # roles      = [aws_iam_role.laravel_ecs_execution_role.name]
}

# ECSタスク実行ロールに、ECSタスク実行用の公式IAMポリシーを付与
resource "aws_iam_role_policy_attachment" "laravel_ecs_execution_role_policy_attachment" {
  role       = aws_iam_role.laravel_ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
resource "aws_iam_role_policy_attachment" "laravel_ecs_execution_role_ssm_attachment" {
  role       = aws_iam_role.laravel_ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

# ECSタスクロールに、パラメータストアのためのIAMポリシーを付与する
resource "aws_iam_role_policy_attachment" "laravel_ecs_role_policy_attachment" {
  role       = aws_iam_role.laravel_ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}
