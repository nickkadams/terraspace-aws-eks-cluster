# Docs: https://terraspace.cloud/docs/config/reference/
Terraspace.configure do |config|
  config.logger.level = :info  
  config.layering.show = true
  # config.layering.mode = "provider"
  # config.all.concurrency = 10 
  config.test_framework = "rspec"
  config.allow.envs = ["dev", "prod"]
  config.allow.regions = ["us-gov-east-1", "us-gov-west-1"]
  # config.all.exclude_stacks = ["eks"]
  # copy_modules setting introduced 2.2.5 to speed up terraspace build
  config.build.copy_modules = true
end
