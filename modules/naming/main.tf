terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5.0"
    }
  }
}

variable "prefix" {
  description = "Name prefix, usually <team>-<environment>."
  type        = string
}

variable "component" {
  description = "Component the name is for, e.g. api or worker."
  type        = string
}

resource "random_pet" "this" {
  prefix    = "${var.prefix}-${var.component}"
  length    = 1
  separator = "-"
}

output "name" {
  description = "Generated name for the component."
  value       = random_pet.this.id
}
