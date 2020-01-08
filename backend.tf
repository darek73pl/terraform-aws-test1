terraform {
    backend "s3" {
        bucket = "dar-terraform"
        key    = "test1/terraform.tfstate"
        region = "eu-central-1"
        dynamodb_table = "terraform-state-lock-dynamo"
  }
}
