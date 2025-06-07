provider "akamai" {
  edgerc         = "~/.edgerc"
  config_section = "gss-demo"
}

locals {
  # looks like sometimes we should remove the grp_ of a group_id, just do it.
  group_id = replace(data.akamai_contract.contract.group_id, "grp_", "")

  # our statically defined security policies that are used in the match targets.
  security_policies = {
    low    = "ewcr_207932"
    medium = "6666_76098"
    high   = "0000_68583"
  }
}

# using standard akamai_contracts to get contract/group information for active group
data "akamai_contract" "contract" {
  group_name = var.group_name
}

# get information about our security configuration based on name
data "akamai_appsec_configuration" "my_configuration" {
  name = var.security_config_name
}

# we're first going to import our existing security configuration
# this is not needed if we're creating a new one via Terraform and managed by Terraform
# https://developer.hashicorp.com/terraform/language/import
import {
  to = resource.akamai_appsec_configuration.appsec_config
  id = data.akamai_appsec_configuration.my_configuration.id
}

# security policy is created in the Akamai Control Center, so this is our import target
# so all security settings are configured via the Akamai Control Center, we're only going to change the match-targets.
resource "akamai_appsec_configuration" "appsec_config" {
  name        = var.security_config_name
  group_id    = local.group_id
  contract_id = data.akamai_contract.contract.id
  description = "Security configuration for Akamai Terraform demo"
  # we're combining non Terraform managed hosts with the hostnames that are managed by Terraform
  # so if there are hosts added to the security configuration that are not managed by Terraform, we can still use them.
  host_names = distinct(concat(var.non_tf_managed_hosts, (flatten(values(var.policy_to_hostnames_map)))))
}

# create a new match target but if number of hosts is 0, delete it otherwise it will become a catch all
# we're going to create three match targets, low, medium, high
# new match targets will be added to the end of the list so you can have a default catch-all match target at the top.
resource "akamai_appsec_match_target" "my-low-match-target" {
  count     = length(var.policy_to_hostnames_map["low"]) > 0 ? 1 : 0
  config_id = data.akamai_appsec_configuration.my_configuration.id
  match_target = templatefile("${path.module}/templates/match_target.tpl", {
    hostnames = var.policy_to_hostnames_map["low"]
    policy_id = local.security_policies["low"]
  })
}

resource "akamai_appsec_match_target" "my-medium-match-target" {
  count     = length(var.policy_to_hostnames_map["medium"]) > 0 ? 1 : 0
  config_id = data.akamai_appsec_configuration.my_configuration.id
  match_target = templatefile("${path.module}/templates/match_target.tpl", {
    hostnames = var.policy_to_hostnames_map["medium"]
    policy_id = local.security_policies["medium"]
  })
}

resource "akamai_appsec_match_target" "my-high-match-target" {
  count     = length(var.policy_to_hostnames_map["high"]) > 0 ? 1 : 0
  config_id = data.akamai_appsec_configuration.my_configuration.id
  match_target = templatefile("${path.module}/templates/match_target.tpl", {
    hostnames = var.policy_to_hostnames_map["high"]
    policy_id = local.security_policies["high"]
  })
}
