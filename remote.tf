terraform {
  backend "s3" {
    bucket = "bucketfnc"
    key    = "terraform-nx/terraform.state"
    region = "us-east-2"
  }
}
