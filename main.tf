locals {
  name_prefix = "${var.team}-${var.environment}"

  tags = {
    environment = var.environment
    team        = var.team
    managed_by  = "terraform"
  }

  announce_command = "echo 'platform ${local.name_prefix} released with ${random_id.release.hex}'"
}

module "api_name" {
  source = "./modules/naming"

  prefix    = local.name_prefix
  component = "api"
}

module "worker_name" {
  source = "./modules/naming"

  prefix    = local.name_prefix
  component = "worker"
}

resource "random_pet" "cluster" {
  prefix = local.name_prefix
  length = 2
}

resource "random_id" "release" {
  keepers = {
    cluster = random_pet.cluster.id
  }
}

resource "time_rotating" "signing" {
  rotation_days = var.secret_rotation_days
}

resource "tls_private_key" "platform" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "tls_self_signed_cert" "platform" {
  private_key_pem = tls_private_key.platform.private_key_pem

  subject {
    common_name  = "${random_pet.cluster.id}.internal"
    organization = var.team
  }

  validity_period_hours = var.cert_validity_hours

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

data "http" "upstream" {
  url = var.health_check_url

  request_headers = {
    Accept = "application/json"
  }

  lifecycle {
    postcondition {
      condition     = contains([200], self.status_code)
      error_message = "Upstream ${var.health_check_url} returned HTTP ${self.status_code}; expected 200."
    }
  }
}

resource "terraform_data" "announce" {
  triggers_replace = [local.announce_command]

  input = merge(local.tags, {
    cluster = random_pet.cluster.id
    api     = module.api_name.name
    worker  = module.worker_name.name
  })

  provisioner "local-exec" {
    command = local.announce_command
  }
}
