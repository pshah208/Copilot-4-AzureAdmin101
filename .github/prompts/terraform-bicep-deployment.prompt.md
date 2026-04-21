---
mode: 'agent'
description: 'Generate production-ready Terraform and Azure Bicep IaC code with remote state, modular structure, security defaults, and GitHub Actions CI/CD pipelines.'
applyTo: '**/*.tf,**/*.tfvars,**/*.bicep,**/*.bicepparam'
---

# Terraform & Bicep – Azure Resource Deployment Skill

## Description
Use this skill to create, validate, and deploy Azure resources using Terraform or Azure Bicep, following IaC best practices and the CAF module structure.

---

## Prompt

You are an Azure Infrastructure-as-Code expert. Help me create and deploy the following Azure resources:

**Resources to deploy**: ${input:resources:Describe the resources – e.g. "An Azure Kubernetes Service cluster with Azure CNI networking, Azure AD integration, and a Log Analytics workspace for monitoring"}
**IaC tool**: ${input:tool:Choose: terraform / bicep / both}
**Target environment**: ${input:environment:dev / staging / prod}
**Region**: ${input:region:e.g. eastus, westeurope, australiaeast}

---

### Terraform Guidance

#### Project Structure
```
terraform/
├── main.tf            # Root module – orchestrates child modules
├── variables.tf       # Input variable declarations
├── outputs.tf         # Output value declarations
├── terraform.tfvars   # Variable values (gitignored for secrets)
├── versions.tf        # Required providers & Terraform version
├── backend.tf         # Remote state (Azure Storage)
└── modules/
    └── <module-name>/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

#### Best Practices
- Pin provider versions: `azurerm ~> 3.0`
- Use **remote state** in Azure Blob Storage with state locking via Lease
- Use `terraform.tfvars` for environment-specific values; never hardcode secrets
- Enable `prevent_destroy = true` lifecycle for critical resources (Key Vault, Storage)
- Tag all resources via `default_tags` on the `azurerm` provider block
- Use **data sources** to reference existing resources rather than hardcoding IDs
- Run `terraform fmt`, `terraform validate`, and `tflint` before applying

#### Security Requirements
- Store secrets in **Azure Key Vault**, reference via `azurerm_key_vault_secret` data source
- Use **Managed Identity** for Terraform state backend authentication where possible
- Enable `soft_delete_retention_days` and `purge_protection_enabled` on Key Vault
- All storage accounts: `https_only = true`, `min_tls_version = "TLS1_2"`

---

### Bicep Guidance

#### Project Structure
```
bicep/
├── main.bicep              # Entry point – calls modules
├── parameters/
│   ├── dev.bicepparam      # Dev environment parameters
│   ├── staging.bicepparam  # Staging parameters
│   └── prod.bicepparam     # Prod parameters
└── modules/
    └── <module-name>.bicep
```

#### Best Practices
- Use **`targetScope`** at the top (`subscription` for landing zone, `resourceGroup` for apps)
- Prefer **`existing`** keyword to reference pre-existing resources
- Use `@description()` decorator on every parameter and output
- Use `@secure()` decorator for sensitive parameters
- Enable **what-if deployment** before applying: `az deployment sub what-if`
- Use **deployment stacks** for lifecycle management in production

#### Security Requirements
- Pass secrets via `@secure()` parameters only; never embed in templates
- Enable diagnostic settings on every resource using a `diagnosticSettings` module
- Use `'TLS1_2'` as minimum TLS version for all storage and web resources

---

### Deployment Pipeline (GitHub Actions)

Provide a GitHub Actions workflow for:
1. `terraform plan` / `az bicep build` on Pull Request
2. `terraform apply` / `az deployment` on merge to `main`
3. Drift detection on a scheduled cron

### Output Format
- Complete Terraform **or** Bicep code (depending on chosen tool)
- `README.md` for the IaC module
- GitHub Actions workflow YAML
- Post-deployment validation commands (Azure CLI)
