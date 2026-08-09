terraform {
  backend "s3" {
    bucket         = "my-tf-state-bucket-ap-south-2" # Match your S3 bucket name
    key            = "dev/terraform.tfstate"         # Path within the bucket
    region         = "ap-south-2"
    use_lockfile   = true                            # Enables native S3 state locking
    encrypt        = true
  }
}