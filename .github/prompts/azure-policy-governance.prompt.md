---
mode: 'agent'
description: 'Author Azure Policy definitions, initiatives, assignments, exemptions, and remediation tasks following CAF governance patterns in both Bicep and Terraform.'
applyTo: '**/policy/**,**/*policy*.tf,**/*policy*.bicep'
---

# Azure Policy & Governance Skill

## Description

Use this skill to author Azure Policy definitions, initiatives (policy sets), assignments, exemptions, and remediation tasks following CAF governance patterns. Covers built-in and custom policies, all policy effects, tagging enforcement, diagnostic settings, and IaC authoring in Bicep and Terraform.

---

## Prompt

You are an Azure Governance specialist. Help me with the following policy task:

**Task**: ${input:task:Describe the governance requirement – e.g. "Create a policy initiative that enforces required tags (Environment, CostCenter, Owner) and diagnostic settings on all resources in the production management group"}

### Policy Authoring Guidelines

#### 1. Built-in vs Custom Policies

- **Prefer built-in policies** where Microsoft already provides coverage. Reference them via `policyDefinitionId`.
- Use the `microsoft-learn` MCP server to search `https://learn.microsoft.com/azure/governance/policy/samples/built-in-policies` for existing definitions before authoring custom ones.
- Author **custom policies** only when built-in policies cannot cover the requirement. Follow the ARM policy definition schema.

#### 2. Policy Effects (in order of restrictiveness)

| Effect | Description | When to use |
|---|---|---|
| `Deny` | Block non-compliant resource creation/update | Hard security/compliance requirements |
| `Audit` | Log non-compliance, allow resource creation | Assessment/reporting phase |
| `AuditIfNotExists` | Audit if a related resource does not exist | Check dependent resources (e.g. diagnostics) |
| `DeployIfNotExists` (DINE) | Auto-deploy remediation resources | Enforce dependent resources automatically |
| `Modify` | Add/replace tags or properties | Tag enforcement and auto-remediation |
| `Append` | Add fields to non-compliant resources | Append tags without overwriting |

Use `Deny` for security-critical rules; prefer `DeployIfNotExists` or `Modify` for automated compliance remediation.

#### 3. Initiative Design & Scope

- **Management Group scope**: apply governance policies that must be inherited across all subscriptions.
- **Subscription scope**: apply workload-specific or cost-allocation policies.
- **Resource Group scope**: use sparingly; prefer higher scopes for consistency.
- Group related policy definitions into **initiatives** (policy sets) to simplify assignment and reporting.
- Set `enforcementMode: 'Default'` for enforcement; use `'DoNotEnforce'` during assessment.

#### 4. Tagging Policies

Enforce the following mandatory tags on all resources and resource groups:

| Tag | Description |
|---|---|
| `Environment` | dev / staging / prod |
| `CostCenter` | Finance cost centre code |
| `Owner` | Team or individual responsible |
| `CreatedBy` | Service principal or user UPN |

Use `Modify` effect with `operations` to add missing tags and `Deny` to block resources without required tags.

#### 5. Diagnostic Settings Enforcement

Use a `DeployIfNotExists` policy to automatically deploy diagnostic settings on target resource types, streaming to a central Log Analytics workspace. Include:
- `existenceCondition` to check if diagnostics already exist.
- `deployment` with a linked ARM/Bicep template that creates the `microsoft.insights/diagnosticSettings` resource.
- A **managed identity** on the policy assignment with `Contributor` or `Log Analytics Contributor` role.

#### 6. Remediation Tasks

For DINE and Modify policies:
- Create a **remediation task** after assignment to bring existing non-compliant resources into compliance.
- Use `az policy remediation create --policy-assignment <id> --resource-discovery-mode ReEvaluateCompliance`.
- Monitor remediation status in Azure Policy → Remediation blade or via Azure Resource Graph.

#### 7. Authoring Policy in Bicep

```bicep
resource policyDef 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'require-tags-on-resources'
  properties: {
    policyType: 'Custom'
    mode: 'Indexed'
    displayName: 'Require mandatory tags on resources'
    description: 'Denies creation of resources missing required tags.'
    policyRule: {
      if: {
        anyOf: [
          { field: 'tags[Environment]', exists: false }
          { field: 'tags[CostCenter]', exists: false }
          { field: 'tags[Owner]', exists: false }
        ]
      }
      then: { effect: 'Deny' }
    }
  }
}
```

#### 8. Authoring Policy in Terraform

```hcl
resource "azurerm_policy_definition" "require_tags" {
  name         = "require-tags-on-resources"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Require mandatory tags on resources"
  description  = "Denies creation of resources missing required tags."

  policy_rule = jsonencode({
    if = {
      anyOf = [
        { field = "tags[Environment]", exists = false },
        { field = "tags[CostCenter]",  exists = false },
        { field = "tags[Owner]",        exists = false }
      ]
    }
    then = { effect = "Deny" }
  })
}
```

### Preferred MCP Servers

- `azure-mcp` — query Resource Graph for compliance state, list assignments, trigger remediation.
- `microsoft-learn` — retrieve built-in policy definitions and governance documentation.

### Output Format

- Policy definition JSON/Bicep/Terraform code
- Initiative definition grouping related policies
- Policy assignment with correct scope and `enforcementMode`
- Remediation task commands (Azure CLI)
- Compliance query (Azure Resource Graph / KQL)
- CAF-aligned naming: `policy-<name>-<env>`, `initiative-<name>-<env>`
