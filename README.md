# Terraform Akamai Security Configuration Module

This Terraform module manages Akamai Application Security configurations by dynamically creating match targets based on hostnames retrieved from Terraform Cloud workspaces and assigns them to different security policies (low, medium, high).

## Overview

The module integrates with Terraform Cloud to automatically discover hostnames from multiple workspaces within a project and assigns them to appropriate security policies. It creates match targets in an existing Akamai Application Security configuration and manages hostname-to-security-policy mappings.

## Features

- **Dynamic hostname discovery**: Automatically retrieves hostnames from Terraform Cloud workspaces
- **Multi-tier security policies**: Supports low, medium, and high security policy levels
- **Flexible hostname assignment**: Combines Terraform-managed and non-Terraform hostnames
- **Template-based match targets**: Uses JSON templates for consistent match target creation
- **Validation**: Ensures hostname uniqueness and required policy keys

## Prerequisites

- Terraform >= 1.5.0
- Akamai Terraform Provider >= 8.0.0
- Existing Akamai Application Security configuration
- Terraform Cloud organization and project setup
- Akamai contract and group access

## Usage

### Basic Usage

```hcl
module "security_config" {
  source = "./terraform-security-config"

  organization           = "your-tfc-org"
  project               = "your-project-name"
  security_config_name  = "your-security-config"
  group_name           = "Your-Akamai-Group"

  policy_to_hostnames_map = {
    low    = ["hostname-1.examples.com"]
    medium = ["hostname-2.example.com"]
    high   = ["hostname-3.example.com"]
  }

  non_tf_managed_hosts = ["legacy.example.com"]
}
```

### Default Policy to Hostnames Map

```hcl
{
  low    = ["ew.example.com"]
  medium = ["bms.example.com"]
  high   = ["bmp.example.com"]
}
```

## Outputs

| Name                             | Description                                                                    |
| -------------------------------- | ------------------------------------------------------------------------------ |
| `security_config_name_hostnames` | Hostnames attached to this security configuration with their security policies |
| `merged_policy_to_hostnames_map` | Merged map of security policies and hostnames from all sources                 |

## How It Works

1. **Workspace Discovery**: The module queries Terraform Cloud to find all workspaces in the specified project
2. **Hostname Extraction**: Extracts hostnames and security policy preferences from workspace outputs
3. **Policy Assignment**: Assigns hostnames to security policies (defaults to "low" if not specified)
4. **Hostname Merging**: Combines dynamically discovered hostnames with statically defined ones
5. **Match Target Creation**: Creates Akamai match targets for each security policy level that has hostnames
6. **Configuration Update**: Updates the Akamai security configuration with the new hostnames

## Security Policies

The module uses predefined security policy IDs:

- **Low**: `ewcr_207932`
- **Medium**: `6666_76098`
- **High**: `0000_68583`

These IDs correspond to existing security policies in your Akamai configuration.

## Match Target Template

The module uses a JSON template (`templates/match_target.tpl`) to create consistent match targets:

```json
{
  "defaultFile": "NO_MATCH",
  "isNegativePathMatch": false,
  "type": "website",
  "filePaths": ["/*"],
  "hostnames": ["your-hostnames-here"],
  "securityPolicy": {
    "policyId": "policy-id-here"
  }
}
```

## Important Notes

### Import Behavior

- The module imports an existing Akamai security configuration rather than creating a new one
- Match targets are created fresh by Terraform - existing match targets are not imported

### Hostname Management

- All hostnames must be unique across all security policy levels
- Hostnames from Terraform Cloud workspaces are automatically discovered
- Additional hostnames can be added via `policy_to_hostnames_map` and `non_tf_managed_hosts`
- Inactive hostnames will cause input errors

### Terraform Cloud Integration

- Requires proper Terraform Cloud authentication and permissions
- Workspaces must output `hostnames` and optionally `security_policy` values
- The module dynamically adapts when new workspaces are added to the project

## Workspace Output Requirements

For automatic hostname discovery, your Terraform Cloud workspaces should output:

```hcl
output "hostnames" {
  description = "List of hostnames for this property"
  value       = ["example.com", "www.example.com"]
}

output "security_policy" {
  description = "Security policy level for this property"
  value       = "medium"  # Optional: defaults to "low"
}
```

## Example Configuration

See the included configuration files for a complete example of how the module integrates with Terraform Cloud and manages Akamai security configurations.

## License

This module is available under the terms specified in your organization's licensing agreement.
