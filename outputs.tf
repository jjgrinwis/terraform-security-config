
output "security_config_name_hostnames" {
  description = "Hostnames attached to this security configuration"
  value       = data.akamai_appsec_configuration.my_configuration.host_names
}
