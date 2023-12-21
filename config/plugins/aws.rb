TerraspacePluginAws.configure do |config|
    config.auto_create = true
    config.tags = {Environment: "dev", Owner: "myuser", Terraform: "true", VCS: "true", Workspace: "default"} # set for both s3 bucket and dynamodb table
    config.tag_existing = false  
    config.s3.access_logging = false
    config.s3.block_public_access = true
    config.s3.encryption = true
    config.s3.enforce_ssl = true
    config.s3.lifecycle = true
    config.s3.versioning = true
    config.s3.secure_existing = false
    # config.s3.tags = {} # override config.tags setting
    config.dynamodb.encryption = true
    config.dynamodb.kms_master_key_id = nil
    config.dynamodb.sse_type = "KMS"
    # config.dynamodb.tags = {} # override config.tags setting
end
