variable "security_config_name" {
  description = "Name of the security configuration to be used"
  type        = string
  default     = "jgrinwis-sc"
}

# below some required input vars
variable "group_name" {
  description = "Akamai group to use this resource in"
  type        = string
  default     = "Akamai Demo-M-1YX7F61"
}

# our var that defines policy to hostname lists mapping
# added some validation to ensure that the right keys are present and that all hostnames are unique across the lists
variable "policy_to_hostnames_map" {
  description = "Attach hostnames to certain security policies. This is a map of lists, where each list contains hostnames that are assigned to a specific security policy."
  type        = map(list(string))
  default = {
    low    = ["ew.grinwis.com"]
    medium = ["bms.grinwis.com"]
    high   = ["bmp.grinwis.com"]
  }
  validation {
    condition = (
      # Ensure all required keys exist
      alltrue([
        contains(keys(var.policy_to_hostnames_map), "low"),
        contains(keys(var.policy_to_hostnames_map), "medium"),
        contains(keys(var.policy_to_hostnames_map), "high")
      ]) &&
      # Ensure all hostnames are unique across all policy levels
      length(flatten(values(var.policy_to_hostnames_map))) ==
      length(distinct(flatten(values(var.policy_to_hostnames_map))))
    )
    error_message = "The map must contain keys 'low', 'medium', and 'high', and all hostnames must be unique across all lists."
  }
}

# a list of hostnames not managed by Terraform, but part of the security configuration
variable "non_tf_managed_hosts" {
  description = "List of hostnames that are not managed by Terraform, but are part of the security configuration."
  type        = list(string)
  default     = ["ew.grinwis.com"]
  validation {
    condition     = length(var.non_tf_managed_hosts) == length(distinct(var.non_tf_managed_hosts))
    error_message = "All elements in the non_tf_managed_hosts list must be unique."
  }
}

# a version 
/* variable "policy_config" {
  description = "Policy definitions including policy ID and associated hostnames."
  type = map(object({
    policy_id = string
    hostnames = list(string)
  }))
  default = {
    low = {
      policy_id = "ewcr_207932"
      hostnames = ["ew.grinwis.com"]
    }
    medium = {
      policy_id = "6666_76098"
      hostnames = ["bms.grinwis.com"]
    }
    high = {
      policy_id = "0000_68583"
      hostnames = ["bmp.grinwis.com"]
    }
  }

  validation {
    condition = length(distinct(flatten([for v in var.policy_config : v.hostnames]))) == length(flatten([for v in var.policy_config : v.hostnames]))
    error_message = "All hostnames across policy_config must be unique."
  }
} */


