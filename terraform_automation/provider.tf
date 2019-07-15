terraform {
  required_version = "~> 0.12.4"
}

provider "aws" {
  version = "2.7.0"

  region = "${var.aws_region}"
}
