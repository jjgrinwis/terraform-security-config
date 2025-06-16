provider "akamai" {
  edgerc         = "~/.edgerc"
  config_section = "gss-demo"
}

# lookup our terraform cloud project by name created in our tf cloud org
# we need to lookup workspaces on project level as we can't assign labels when creating a workspace via no-code module.
# data should contain workspace_ids and a workspace_names lists.
data "tfe_project" "mendix_project" {
  name         = var.project
  organization = var.organization
}

# let's lookup all the different workspace names in our project
# this is dynamic. So when a new property/workspace is created, it will automatically be added to the list of workspaces.
data "tfe_outputs" "all" {
  for_each     = data.tfe_project.mendix_project.workspace_names
  organization = var.organization
  workspace    = each.key
}


locals {
  # we want to create a map of security policies and hostnames
  # property_name is the key and it has a list of hostnames and a property level security policy with a default of "low".
  # in the future we might want to change this to a security policy per hostname.
  # we will output this variable to show which property/hostname is assigned to which security policy.
  security_policy_hostnames = {
    for property_name, item in data.tfe_outputs.all :
    property_name => {
      security_policy = lookup(item.nonsensitive_values, "security_policy", "low")
      hostnames       = lookup(item.nonsensitive_values, "hostnames", [])
    }
    if length(lookup(item.nonsensitive_values, "hostnames", [])) > 0
  }

  # this is our flattened map of hostnames per security policy
  # they keys are going to be attached to our variable
  hostnames_by_policy = {
    for policy in ["low", "medium", "high"] :
    policy => flatten([
      for item in local.security_policy_hostnames :
      item.hostnames
      if item.security_policy == policy
    ])
  }
  # Merge both maps — concatenate existing and new hostnames
  # this can be used to create some static hostnames that are not managed by Terraform but you still want to assign them to that terraform managed security policy
  merged_policy_to_hostnames_map = {
    for policy in ["low", "medium", "high"] :
    policy => concat(
      lookup(local.hostnames_by_policy, policy, []),
      lookup(var.policy_to_hostnames_map, policy, [])
    )
  }

  # looks like sometimes we should remove the grp_ of a group_id, just do it.
  group_id = replace(data.akamai_contract.contract.group_id, "grp_", "")

  # our statically defined security policies ids that are used in the match targets.
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
# https:#developer.hashicorp.com/terraform/language/import
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
  # but be aware, hostname should be active, otherwise you will get an input error. 
  host_names = distinct(concat(var.non_tf_managed_hosts, (flatten(values(local.merged_policy_to_hostnames_map)))))
}

# create a new match target but if number of hosts is 0, delete it otherwise it will become a catch all
# we're going to create three match targets, low, medium, high
# new match targets will be added to the end of the list so you can have a default catch-all match target at the top.
resource "akamai_appsec_match_target" "my-low-match-target" {
  count     = length(local.merged_policy_to_hostnames_map["low"]) > 0 ? 1 : 0
  config_id = data.akamai_appsec_configuration.my_configuration.id
  match_target = templatefile("${path.module}/templates/match_target.tpl", {
    hostnames = local.merged_policy_to_hostnames_map["low"]
    policy_id = local.security_policies["low"]
  })
}

resource "akamai_appsec_match_target" "my-medium-match-target" {
  count     = length(local.merged_policy_to_hostnames_map["medium"]) > 0 ? 1 : 0
  config_id = data.akamai_appsec_configuration.my_configuration.id
  match_target = templatefile("${path.module}/templates/match_target.tpl", {
    hostnames = local.merged_policy_to_hostnames_map["medium"]
    policy_id = local.security_policies["medium"]
  })
}

resource "akamai_appsec_match_target" "my-high-match-target" {
  count     = length(local.merged_policy_to_hostnames_map["high"]) > 0 ? 1 : 0
  config_id = data.akamai_appsec_configuration.my_configuration.id
  match_target = templatefile("${path.module}/templates/match_target.tpl", {
    hostnames = local.merged_policy_to_hostnames_map["high"]
    policy_id = local.security_policies["high"]
  })
}
