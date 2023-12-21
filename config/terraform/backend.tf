# Backend Config Variables Docs
# https://terraspace.cloud/docs/config/backend/variables/
terraform {
  backend "s3" {
    bucket         = "<%= expansion('terraform-state-:ACCOUNT-:REGION-:APP') %>"
    key            = "<%= expansion(':ENV/:EXTRA/:BUILD_DIR/terraform.tfstate') %>"
    region         = "<%= expansion(':REGION') %>"
    encrypt        = true
    dynamodb_table = "<%= expansion('terraform_locks_:APP') %>"
  }
}
