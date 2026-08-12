cluster_name   = "test-cluster-us-east-1"
application    = "test-app"
namespace      = "test-ns"
vpc_id         = "vpc-1234567890abcdef0"
public_subnets = ["subnet-1234567890abcdef0", "subnet-1234567890abcdef1"]
internal       = false
acm_arn        = "arn:aws:acm:us-east-1:123456789012:certificate/aabbcc11-1312-abcd-qwer-1a2s3d4f5g6h"
# Module default is null, but main.tf calls length() on it unconditionally - a
# pre-existing bug unrelated to this test suite; set explicitly to work around it.
s3_logs_bucket_id = ""
