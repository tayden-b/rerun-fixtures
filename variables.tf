variable "environment" {
  description = "Deployment environment used in names and tags."
  type        = string
  default     = "demo"
}

variable "team" {
  description = "Owning team, used as the name prefix."
  type        = string
  default     = "platform"
}

variable "health_check_url" {
  description = "Upstream endpoint the platform depends on."
  type        = string
  default     = "https://httpbin.org/status/404"
}

variable "cert_validity_hours" {
  description = "Validity period of the platform's self-signed certificate."
  type        = number
  default     = 2160
}

variable "min_cert_validity_hours" {
  description = "Guardrail: certificates must be valid for at least this many hours."
  type        = number
  default     = 720
}

variable "secret_rotation_days" {
  description = "How often the platform's signing material rotates."
  type        = number
  default     = 30
}
