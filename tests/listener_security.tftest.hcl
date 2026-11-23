mock_provider "aws" {
  source          = "./tests/mocks/aws"
  override_during = plan

  mock_resource "aws_lb_listener" {
    defaults = {
      routing_http_response_strict_transport_security_header_value = ""
    }
  }
}

mock_provider "cloudflare" {
  source = "./tests/mocks/cloudflare"
}

mock_provider "datadog" {}

run "external_listener_defaults" {
  command = plan

  assert {
    condition     = aws_lb_listener.tls[0].ssl_policy == "ELBSecurityPolicy-TLS13-1-3-PQ-2025-09"
    error_message = "The default policy must retain TLS 1.3-only and offer post-quantum key exchange."
  }

  assert {
    condition     = aws_lb_listener.tls[0].routing_http_response_strict_transport_security_header_value == "max-age=31536000"
    error_message = "The external HTTPS listener must default to one year of host-scoped HSTS."
  }
}

run "strict_tls_preserved" {
  command = plan

  variables {
    tls_listener_version = "1.3"
  }

  assert {
    condition     = aws_lb_listener.tls[0].ssl_policy == "ELBSecurityPolicy-TLS13-1-3-PQ-2025-09"
    error_message = "Explicit TLS 1.3 must select the TLS 1.3-only post-quantum policy."
  }
}

run "explicit_tls_1_2_uses_compatible_policy" {
  command = plan

  variables {
    tls_listener_version = "1.2"
  }

  assert {
    condition     = aws_lb_listener.tls[0].ssl_policy == "ELBSecurityPolicy-TLS13-1-2-Res-PQ-2025-09"
    error_message = "Explicit TLS 1.2 must select the post-quantum policy that supports TLS 1.2 and TLS 1.3."
  }
}

run "internal_listener_omits_hsts" {
  command = plan

  variables {
    internal          = true
    hsts_header_value = "max-age=600"
  }

  assert {
    condition     = aws_lb_listener.tls[0].routing_http_response_strict_transport_security_header_value == ""
    error_message = "Internal HTTPS listeners must leave HSTS to the target."
  }
}

run "external_listener_accepts_custom_hsts" {
  command = plan

  variables {
    hsts_header_value = "max-age=600; includeSubDomains"
  }

  assert {
    condition     = aws_lb_listener.tls[0].routing_http_response_strict_transport_security_header_value == "max-age=600; includeSubDomains"
    error_message = "The external HTTPS listener must accept custom HSTS values."
  }
}

run "external_listener_can_omit_hsts" {
  command = plan

  variables {
    hsts_header_value = null
  }

  assert {
    condition     = aws_lb_listener.tls[0].routing_http_response_strict_transport_security_header_value == ""
    error_message = "With a null override, a new external HTTPS listener must leave HSTS to the target."
  }
}

run "externally_managed_listener_is_untouched" {
  command = plan

  variables {
    create_default_listener = false
  }

  assert {
    condition     = length(aws_lb_listener.tls) == 0
    error_message = "The module must leave listener configuration to the owner when the default listener is disabled."
  }
}
