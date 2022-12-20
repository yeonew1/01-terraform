terraform {
  # 테 라 폼 버 전 지 정 latest version = 1.3.x
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
  ami           = "ami-0ab04b3ccbadfae1f" # ubuntu 20.04 version
  instance_type = "t2.micro"
  key_name = "aws03-key" # key가 쓰고싶을때 사용

  tags = {
    Name = "aws03-terrform-axample"
  }
}
