# ターゲットグループの作成
resource "aws_lb_target_group" "laravel_target_group" {
  name     = "containerTargetGroupByTf"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.laravel_vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 300
  }

  target_type = "ip"

  tags = {
    Name        = "targetGroupByTf"
    Environment = "sandbox"
    Source      = "terraform"
    Project     = "pjCicdEcs"
  }
}

# ALBのリスナーを作成および設定
resource "aws_lb_listener" "laravel_alb_listener" {
  load_balancer_arn = aws_lb.laravel_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.laravel_target_group.arn
  }
}

# ALB の作成
resource "aws_lb" "laravel_alb" {
  name               = "albByTf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.laravel_alb_sg.id]
  subnets            = [aws_subnet.laravel_subnet.id, aws_subnet.laravel_subnet2.id]

  enable_deletion_protection       = false
  enable_http2                     = true
  enable_cross_zone_load_balancing = true

  tags = {
    Name        = "albByTf"
    Environment = "sandbox"
    Source      = "terraform"
    Project     = "pjCicdEcs"
  }
}

# ALB用のセキュリティグループの作成
resource "aws_security_group" "laravel_alb_sg" {
  name_prefix = "elb_sg_by_tf"
  vpc_id      = aws_vpc.laravel_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
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
    Name        = "elbSgByTf"
    Environment = "sandbox"
    Source      = "terraform"
    Project     = "pjCicdEcs"
  }
}
