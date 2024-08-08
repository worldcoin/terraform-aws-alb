variable "cluster_name" {
  description = "Name of the cluster will be used as suffix to all resources"
  type        = string
}

variable "application" {
  description = "Name of application which will be connected to this ALB"
  type        = string
}

variable "namespace" {
  description = "Name of namespace where application is deployed"
  type        = string
}

variable "acm_arn" {
  description = "ARN for ACM certificate used for TLS"
  type        = string
}

variable "acm_extra_arns" {
  description = "ARNs of ACM certificates used for TLS, attached as additional certificates to the main NLB"
  type        = list(string)
  default     = []
}

variable "vpc_id" {
  description = "VPC ID where the NLB will be deployed"
  type        = string
}

variable "s3_logs_bucket_id" {
  description = "The ID of S3 bucket where the ALB logs will be stored, enables logging if set"
  type        = string
  default     = null
}

variable "public_subnets" {
  description = "List of public subnets to use"
  type        = list(string)
}

variable "name_suffix" {
  description = "Part of the name used to differentiate NLBs for multiple traefik instances"
  type        = string
  default     = ""
}

variable "internal" {
  description = "Set NLB to be internal (available only within VPC)"
  type        = bool
}

variable "backend_ingress_rules" {
  description = "The security group rules to allow ingress from."
  type = set(object({
    description     = optional(string, "")
    protocol        = optional(string, "tcp")
    port            = optional(number, 443)
    security_groups = optional(list(string))
    cidr_blocks     = optional(list(string))
  }))
  default = []
}

variable "additional_open_ports" {
  description = "Additional ports accessible from the Internet for the ALB"
  type = set(object({
    port     = number
    protocol = optional(string, "tcp")
  }))
  default = []
}

variable "tls_listener_version" {
  description = "Minimum TLS version served by TLS listener"
  type        = string
  default     = "1.3"
  validation {
    condition     = var.tls_listener_version == "1.2" || var.tls_listener_version == "1.3"
    error_message = "Only TLS >= 1.2 or 1.3 are supported"
  }
}

variable "idle_timeout" {
  description = "The time in seconds that the connection is allowed to be idle"
  type        = number
  default     = 60
}

variable "open_to_all" {
  description = "Allow all traffic to the ALB"
  type        = bool
  default     = false
}

variable "waf_enabled" {
  description = "Enable WAF rules and assignee them to the ALB"
  type        = bool
  default     = false
}

variable "waf_rules" {
  description = "Rule blocks used to identify the web requests that you want to use."
  type = list(object({
    name                                     = string
    priority                                 = number
    managed_rule_group_statement_vendor_name = string
  }))
  default = [
    {
      name                                     = "AWSManagedRulesCommonRuleSet"
      priority                                 = 0
      managed_rule_group_statement_vendor_name = "AWS"
    },
    {
      name                                     = "AWSManagedRulesKnownBadInputsRuleSet"
      priority                                 = 1
      managed_rule_group_statement_vendor_name = "AWS"
    },
    {
      name                                     = "AWSManagedRulesAmazonIpReputationList"
      priority                                 = 2
      managed_rule_group_statement_vendor_name = "AWS"
    },
    {
      name                                     = "AWSManagedRulesAnonymousIpList"
      priority                                 = 3
      managed_rule_group_statement_vendor_name = "AWS"
    },
    {
      name                                     = "AWSManagedRulesSQLiRuleSet"
      priority                                 = 4
      managed_rule_group_statement_vendor_name = "AWS"
    }
  ]
}
