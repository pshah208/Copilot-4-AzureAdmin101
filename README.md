# 🚀 Copilot for Azure Administration 101

> **GitHub Copilot** supercharged with Azure-native skills, MCP servers, and Infrastructure-as-Code templates to accelerate cloud architecture, deployment, and operations.

---

## ✨ Capabilities Overview

| Capability | Description |
|---|---|
| 🏗️ Azure Landing Zone | Design & deploy CAF Enterprise-Scale landing zones |
| 🎨 Architecture Diagramming | Generate Draw.io diagrams with official Azure icons |
| 🔧 Terraform IaC | Modular Terraform templates for Azure resources |
| 💪 Bicep IaC | Idiomatic Bicep modules for Azure deployments |
| 🔍 Troubleshooting | Systematic Azure issue diagnosis & remediation |
| 📚 Microsoft Learn | AI-assisted learning from official Microsoft docs |
| 🔒 Security & Governance | Policy, RBAC, Defender for Cloud out-of-the-box |

---

## 📂 Repository Structure

```
.
├── .github/
│   ├── copilot-instructions.md          # Global Copilot custom instructions
│   ├── prompts/                         # Copilot skill prompt files
│   │   ├── azure-landing-zone.prompt.md
│   │   ├── azure-architecture-design.prompt.md
│   │   ├── azure-troubleshooting.prompt.md
│   │   ├── drawio-architecture.prompt.md
│   │   └── terraform-bicep-deployment.prompt.md
│   └── workflows/
│       ├── terraform-landing-zone.yml   # Terraform CI/CD pipeline
│       └── bicep-landing-zone.yml       # Bicep CI/CD pipeline
├── .vscode/
│   └── mcp.json                         # MCP server configurations
├── terraform/
│   └── landing-zone/                    # Hub-and-spoke landing zone (Terraform)
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── versions.tf
│       ├── terraform.tfvars.example
│       └── modules/
│           ├── hub-network/
│           ├── spoke-network/
│           └── policy/
└── bicep/
    └── landing-zone/                    # Hub-and-spoke landing zone (Bicep)
        ├── main.bicep
        ├── parameters/
        │   └── dev.bicepparam
        └── modules/
            ├── hub-network.bicep
            ├── spoke-network.bicep
            └── log-analytics.bicep
```

---

## 🤖 GitHub Copilot Skills

Skills are prompt files stored in `.github/prompts/`. Open them in VS Code and run them directly with **GitHub Copilot Chat** (`@workspace /use-prompt`), or use them as reference for crafting your own prompts.

### 1. 🏗️ Azure Landing Zone

**File**: `.github/prompts/azure-landing-zone.prompt.md`

Helps you design and deploy a complete Azure Landing Zone following the **Microsoft Cloud Adoption Framework (CAF) Enterprise-Scale** pattern:

- Management Group hierarchy design
- Hub-and-spoke / Virtual WAN connectivity model
- Identity, security, and governance baseline
- Terraform / Bicep deployment artefacts

**Example prompt**:
> *"Design a hub-and-spoke landing zone for a financial services company with 3 spoke subscriptions, ExpressRoute connectivity, and strict PCI-DSS compliance requirements."*

---

### 2. 🎨 Azure Architecture Design

**File**: `.github/prompts/azure-architecture-design.prompt.md`

Produces well-architected Azure solution designs covering all **five WAF pillars**:

- Service selection with justification
- Network topology with NSG rules and private endpoints
- Identity & RBAC model
- Monitoring and alerting strategy
- Cost estimate

**Example prompt**:
> *"Design a multi-region active-active web application architecture for a retail e-commerce platform expecting 100k concurrent users during peak events."*

---

### 3. 🔍 Azure Troubleshooting

**File**: `.github/prompts/azure-troubleshooting.prompt.md`

Systematic diagnostic framework covering:

- Activity Log & Service Health review
- Resource-type specific diagnostic sources (NSG Flow Logs, App Insights, Firewall logs)
- Root cause analysis methodology
- Step-by-step remediation with Azure CLI / PowerShell
- KQL queries for Log Analytics validation

**Example prompt**:
> *"VMs in a spoke VNet cannot reach resources in the hub after deploying Azure Firewall. Traffic appears to be dropped."*

---

### 4. 🎨 Draw.io Architecture Diagramming

**File**: `.github/prompts/drawio-architecture.prompt.md`

Creates professional Azure architecture diagrams in **Draw.io XML format** using official Azure 2023 shape libraries:

- Conceptual, logical, physical, and network-topology diagrams
- Colour-coded components following Microsoft design conventions
- Importable XML output for diagrams.net / VS Code Draw.io extension

**Example prompt**:
> *"Create a Draw.io diagram for a hub-and-spoke network with Azure Firewall, Bastion, ExpressRoute gateway, and three spoke VNets for dev, staging, and production."*

---

### 5. 🔧 Terraform & Bicep Deployment

**File**: `.github/prompts/terraform-bicep-deployment.prompt.md`

Generates production-ready IaC code following best practices:

- Remote state management (Azure Blob Storage)
- Modular structure with reusable components
- Security defaults (Key Vault secrets, Managed Identity, TLS 1.2)
- GitHub Actions CI/CD pipeline with plan/apply stages and drift detection

**Example prompt**:
> *"Create a Terraform module for an AKS cluster with Azure CNI, Azure AD integration, cluster autoscaler, and a Log Analytics workspace for Container Insights."*

---

## 🔌 MCP Server Configuration

MCP (Model Context Protocol) servers extend GitHub Copilot with live tool capabilities. The configuration is in `.vscode/mcp.json`.

### Setup

1. **Install prerequisites** (Node.js 18+)
2. **Set environment variables** (see table below)
3. Open the repository in VS Code — MCP servers start automatically

### Available MCP Servers

| Server | Package | Purpose |
|---|---|---|
| `azure-mcp` | `@azure/mcp` | Manage Azure resources, query Resource Graph, read logs |
| `drawio-mcp` | `@khulnasoft/drawio-mcp` | Create and edit Draw.io diagrams programmatically |
| `microsoft-learn-mcp` | `@microsoft/learn-mcp` | Search and retrieve official Microsoft documentation |
| `terraform-mcp` | `@hashicorp/terraform-mcp-server` | Run Terraform plans, inspect state, and explore modules |

### Required Environment Variables

```bash
# Azure MCP
export AZURE_SUBSCRIPTION_ID="<your-subscription-id>"
export AZURE_TENANT_ID="<your-tenant-id>"
export AZURE_CLIENT_ID="<your-client-id>"
export AZURE_CLIENT_SECRET="<your-client-secret>"   # or use Azure CLI login

# Terraform MCP (optional – Terraform Cloud)
export TF_TOKEN_app_terraform_io="<your-tfc-token>"
```

> **Tip**: Use `az login` instead of a service principal for local development. The Azure MCP server will pick up your CLI credentials automatically.

---

## 🏗️ Infrastructure as Code Templates

### Terraform – Azure Landing Zone

Deploys a **hub-and-spoke** network topology with:

| Component | Details |
|---|---|
| Hub VNet | Configurable address space |
| Azure Firewall | Standard SKU, zone-redundant |
| Azure Bastion | Standard SKU for secure VM access |
| VPN Gateway | Optional, Generation 2, BGP-enabled |
| Spoke VNets | N spokes via `var.spokes` map |
| VNet Peerings | Bidirectional hub ↔ spoke |
| Log Analytics | Central workspace for all diagnostics |
| Defender for Cloud | Servers, Storage, Key Vault plans |
| Azure Policy | Required tags + diagnostic settings |

#### Quick Start

```bash
cd terraform/landing-zone

# Copy and edit the example vars file
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your subscription ID, tenant ID, etc.

# Authenticate
az login
az account set --subscription "<your-subscription-id>"

# Deploy
terraform init
terraform plan
terraform apply
```

---

### Bicep – Azure Landing Zone

Equivalent hub-and-spoke deployment using **Azure Bicep** with `targetScope = 'subscription'`.

#### Quick Start

```bash
# Authenticate
az login
az account set --subscription "<your-subscription-id>"

# What-If (preview changes)
az deployment sub what-if \
  --location eastus \
  --template-file bicep/landing-zone/main.bicep \
  --parameters bicep/landing-zone/parameters/dev.bicepparam

# Deploy
az deployment sub create \
  --location eastus \
  --template-file bicep/landing-zone/main.bicep \
  --parameters bicep/landing-zone/parameters/dev.bicepparam
```

---

## 🔄 CI/CD Pipelines

### Terraform Pipeline (`.github/workflows/terraform-landing-zone.yml`)

| Trigger | Action |
|---|---|
| Pull Request | `terraform validate` + `terraform plan` → comment on PR |
| Merge to `main` | `terraform apply` |
| Schedule (Mon 06:00 UTC) | Drift detection via `terraform plan -detailed-exitcode` |

### Bicep Pipeline (`.github/workflows/bicep-landing-zone.yml`)

| Trigger | Action |
|---|---|
| Pull Request | `bicep build` + `az deployment sub what-if` → comment on PR |
| Merge to `main` | `az deployment sub create` |

### Required GitHub Secrets

```
AZURE_TENANT_ID
AZURE_SUBSCRIPTION_ID
AZURE_CLIENT_ID          # Service principal with Contributor + RBAC Admin
```

> The pipelines use **OIDC federated credentials** — no long-lived secrets required. Configure Workload Identity Federation in Entra ID for the best security posture.

---

## 🔒 Security & Compliance Defaults

All templates enforce the following by default:

- ✅ **Tagging policy** – `Environment`, `CostCenter`, `Owner`, `CreatedBy` required on all resources
- ✅ **Diagnostic settings** – all resources stream logs to central Log Analytics
- ✅ **TLS 1.2 minimum** for all storage and web resources
- ✅ **Private endpoints** preferred over public endpoints for PaaS services
- ✅ **Managed Identities** for service-to-service authentication
- ✅ **Microsoft Defender for Cloud** enabled across Servers, Storage, and Key Vault
- ✅ **Zone-redundant** deployments for critical network resources (Firewall, Bastion, Gateways)

---

## 📚 References

| Resource | Link |
|---|---|
| Microsoft Cloud Adoption Framework | https://learn.microsoft.com/azure/cloud-adoption-framework/ |
| Azure Landing Zones | https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/ |
| Azure Well-Architected Framework | https://learn.microsoft.com/azure/well-architected/ |
| Terraform AzureRM Provider | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs |
| Azure Bicep Documentation | https://learn.microsoft.com/azure/azure-resource-manager/bicep/ |
| Draw.io Azure Shape Library | https://diagrams.net |
| MCP Specification | https://modelcontextprotocol.io |

---

## 🤝 Contributing

1. Fork this repository
2. Create a feature branch: `git checkout -b feature/my-new-skill`
3. Add your skill prompt to `.github/prompts/`
4. Update this README
5. Open a pull request

---

*Built with ❤️ using GitHub Copilot, Azure, Terraform, and Bicep.*
