# Docs: https://www.terraform.io/docs/providers/aws/index.html
provider "aws" {
  default_tags {
    tags = {
      Environment = "<%= expansion(':ENV') %>"
      Owner       = "<%= expansion(':APP') %>"
      Terraform   = "true"
      VCS         = "true"
      Workspace   = terraform.workspace
    }
  }
}
