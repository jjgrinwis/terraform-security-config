
output "security_config_name_hostnames" {
  description = "Hostnames attached to this security configuration"
  value       = local.security_policy_hostnames
}
output "merged_policy_to_hostnames_map" {
  description = "Merged map of security policies and hostnames"
  value       = local.merged_policy_to_hostnames_map
}
