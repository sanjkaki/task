terraform {
  backend "s3" {
    bucket = "sanjkaki-terraform"
    key = "sanjkaki/task.tfstate"
    region = "us-east-1"
    
  }
}