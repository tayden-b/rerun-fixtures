terraform {
  required_version = "~> 1.14"

  cloud {
    organization = "hashi-org-TF"

    workspaces {
      name = "rerun-fixtures"
    }
  }

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "3.9.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.4.2"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.6.3"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.14.2"
    }
  }
}
