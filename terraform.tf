# GCP Cloud Armor Terraform Module

Terraform module to create and manage Google Cloud Armor security policies.

## Requirements

- Terraform >= 1.5.0
- Google Terraform Provider >= 6.0.0 and < 8.0.0
- Compute Security Policies API enabled in GCP.

## Usage

Refer to docs/sample.tf for module usage.

## Inputs

| Name | Description | Required |
|---|---|---|
| project_id | GCP project ID | Yes |
| name | Cloud Armor policy name | Yes |
| description | Policy description | No |
| rules | Security policy rules | Yes |

## Outputs

| Name | Description |
|---|---|
| security_policy_id | Security policy ID |
| security_policy_name | Security policy name |
| security_policy_self_link | Security policy self link |

## Testing

Run the following commands from the test directory:

terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
