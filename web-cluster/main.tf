terraform {
  # 테 라 폼 버 전 지 정
  required_version = ">= 1.0.0, < 2.0.0"

  # 공 급 자 버 전 지 정
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

# 시작 템플릿 설정
resource "aws_launch_template" "example" {
  image_id               = "ami-0ab04b3ccbadfae1f"
  instance_type          = "t2.micro"
  key_name               = "aws03-key"
  vpc_security_group_ids = [aws_security_group.instance.id]

  user_data = base64encode(data.template_file.web_output.rendered)

  lifecycle {
    create_before_destroy = true
  }
}

# 오토 스케일링 그룹
resource "aws_autoscaling_group" "example" {
  availability_zones = ["ap-northeast-2a", "ap-northeast-2c"]

  name             = "terraform-asg-example"
  desired_capacity = 1
  min_size         = 1
  max_size         = 2

  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"

  launch_template {
    id      = aws_launch_template.example.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = "aws03-terraform-asg-example"
    propagate_at_launch = true
  }
}

# 로드밸런서
resource "aws_lb" "example" {
  name               = "aws03-terraform-asg-example"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids
  security_groups    = [aws_security_group.alb.id]
}

# 로드밸런서 리스너
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port              = 80
  protocol          = "HTTP"

  # 기본값으로 단순한 404페이지 오류를 반환한다.
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

# 로드 밸런서 리스터 룰 구성
resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}

# 로드밸런서 대상그룹
resource "aws_lb_target_group" "asg" {
  name     = "aws03-terraform-asg-example"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}


# 보안그룹 - instance
resource "aws_security_group" "instance" {
  name = "aws03-terraform-example-instance"

  # 인바운드 규칙 설정
  ingress {
    from_port   = var.server_port # 출발 포트
    to_port     = var.server_port # 도착 포트
    protocol    = "tcp"           # 프로토콜
    cidr_blocks = ["0.0.0.0/0"]   # 송신지
  }
}


# 보안그룹 - ALB
resource "aws_security_group" "alb" {
  name = "terraform-example-alb"
  # 인바운드 HTTP 트래픽 허용
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # 모든 아웃바운드 트래픽 허용
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Default VPC 정보 가지고 오기
data "aws_vpc" "default" {
  default = true
}

# Subnet 정보 가지고 오기
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "template_file" "web_output" {
  template = file("${path.module}/web.sh")
  vars = {
    server_port = "${var.server_port}"
  }
}
