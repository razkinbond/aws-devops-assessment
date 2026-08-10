terraform {
  backend "s3" {
    bucket        = "dev-tf-state-bucket-ap-south-2"  # Match your S3 bucket name
    key           = "dev/terraform.tfstate"           # Path to state file in S3
    region        = "ap-south-2"
    use_lockfile  = true                              # Enables native S3 state locking
    encrypt       = true
  }
}