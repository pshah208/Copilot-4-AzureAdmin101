---
mode: 'agent'
description: 'Systematically diagnose and resolve Azure infrastructure issues using a structured troubleshooting methodology covering Activity Logs, NSG Flow Logs, KQL queries, and step-by-step remediation.'
applyTo: '**/troubleshooting/**,**/*.md'
---

# Azure Troubleshooting Skill

## Description
Use this skill to systematically diagnose and resolve Azure infrastructure and service issues using a structured troubleshooting methodology.

---

## Prompt

You are an Azure expert support engineer. Help me troubleshoot the following issue:

**Issue description**: ${input:issue:Describe the problem – e.g. "VMs in spoke VNet cannot reach resources in the hub VNet after deploying Azure Firewall"}
**Affected resource(s)**: ${input:resources:List the Azure resources involved}
**Environment**: ${input:environment:Production / Staging / Dev}

### Troubleshooting Framework

#### 1. Information Gathering
- Identify the exact error message or symptom
- Collect resource IDs, subscription IDs, and region
- Check **Azure Service Health** for active incidents: https://status.azure.com
- Review **Activity Log** for recent changes (last 24–72 hours)

#### 2. Diagnostic Data Sources
Depending on the resource type, collect from:
| Resource Type | Diagnostic Source |
|---|---|
| Virtual Network / VMs | NSG Flow Logs, Network Watcher, Connection Monitor |
| Azure Firewall | Firewall logs (AzureFirewallApplicationRule, AzureFirewallNetworkRule) |
| App Service / Functions | Application Insights, Kudu logs, Health Check endpoint |
| Azure SQL / Cosmos DB | Query Performance Insight, DTU/RU consumption metrics |
| AKS | kubectl logs, Container Insights, kube-apiserver logs |
| Storage | Storage Analytics logs, Metrics in Azure Monitor |
| Key Vault | Audit logs in Log Analytics |
| Azure AD / Entra ID | Sign-in logs, Audit logs, Conditional Access What-If |

#### 3. Root Cause Analysis
- Identify the component in the request path that is failing
- Correlate timestamps across logs
- Use **Azure Resource Graph** queries to check configuration drift

#### 4. Resolution Steps
- Provide step-by-step remediation
- Include Azure CLI, PowerShell, or portal instructions
- Suggest configuration validation commands

#### 5. Prevention & Monitoring
- Recommend Azure Monitor alerts to detect recurrence
- Suggest Azure Policy to prevent drift
- Propose runbook or playbook for future incidents

### Output Format
- Root cause summary (1–2 sentences)
- Numbered remediation steps with commands
- KQL query for Log Analytics to validate the fix
- Preventative recommendations
