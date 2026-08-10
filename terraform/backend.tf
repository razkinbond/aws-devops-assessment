terraform {
  backend "s3" {
    bucket        = "dev-tf-state-bucket-ap-south-2"  # Match your S3 bucket name
    region        = "ap-south-2"
    use_lockfile  = true                              # Enables native S3 state locking
    encrypt       = true
  }
}