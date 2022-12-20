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

resource "aws_instance" "example" {
  ami                    = "ami-0ab04b3ccbadfae1f" # ubuntu 20.04 version
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance.id] 
  
  key_name = "aws03-key"

  user_data = <<-EOF
			  #!/bin/bash
			  echo "Hello, World" > index.html
			  nohup busybox httpd -f -p ${var.server_port} &
			  EOF

  tags = {
    Name = "aws03-terrform-axample"
  }
}

# 보안그룹 생성
resource "aws_security_group" "instance" {
  name = "aws03-terraform-example-instance"

  # 인바운드 규칙 설정
  ingress {
    from_port   = var.server_port # 출발 포트
    to_port     = var.server_port # 도착 포트
    protocol    = "tcp" # 프로토콜
    cidr_blocks = ["0.0.0.0/0"] # 송신지
  }
}

# 출력 지정
output "pulic-ip" {
  value       = aws_instance.example.public_ip
  description = "The public IP of the Instance"
}
