check "certificate_validity" {
  assert {
    condition     = tls_self_signed_cert.platform.validity_period_hours >= var.min_cert_validity_hours
    error_message = "The platform certificate is valid for ${tls_self_signed_cert.platform.validity_period_hours}h; the minimum is ${var.min_cert_validity_hours}h."
  }

  assert {
    condition     = time_rotating.signing.rotation_days <= 90
    error_message = "Signing material must rotate at least every 90 days."
  }
}

# Check blocks only warn, so the same guardrail is enforced as a precondition
# that stops the plan.
resource "terraform_data" "release_gate" {
  input = {
    cluster     = random_pet.cluster.id
    cert_expiry = tls_self_signed_cert.platform.validity_end_time
  }

  lifecycle {
    precondition {
      condition     = tls_self_signed_cert.platform.validity_period_hours >= var.min_cert_validity_hours
      error_message = "Release gate: certificate validity (${tls_self_signed_cert.platform.validity_period_hours}h) is below the ${var.min_cert_validity_hours}h minimum."
    }
  }
}
