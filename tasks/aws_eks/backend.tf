terraform {
  backend "s3" {
    bucket = "your_own_bucket"
    key = "Some_key"
    region = "us-east-1"
    
  }
}
