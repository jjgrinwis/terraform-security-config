terraform {
  # using import so make sure we're using at least TF 1.5.0
  required_version = ">= 1.5.0"
  required_providers {
    akamai = {
      source  = "akamai/akamai"
      version = ">= 8.0.0"
    }
  }
}
