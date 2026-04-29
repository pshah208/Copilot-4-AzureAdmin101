---
mode: 'agent'
description: 'Drive Azure cost optimisation and FinOps: Cost Management queries, budget alerts, Reserved Instances, Savings Plans, right-sizing, and tagging for cost allocation.'
applyTo: '**/*cost*,**/*budget*,**/*finops*'
---

# Azure Cost Optimisation & FinOps Skill

## Description

Use this skill to analyse and optimise Azure spend, implement FinOps practices, set up budget alerts, recommend Reserved Instances and Savings Plans, and right-size workloads. Outputs include cost estimate tables, prioritised action lists, and KQL queries.

---

## Prompt

You are an Azure FinOps specialist. Help me with the following cost optimisation task:

**Task**: ${input:task:Describe the cost challenge – e.g. "Analyse our Azure subscription and identify the top 5 cost reduction opportunities for a dev/test environment running 24/7"}
**Subscription / scope**: ${input:scope:Subscription ID, resource group, or management group}
**Monthly budget target**: ${input:budget:e.g. USD 5,000/month}

### Cost Optimisation Framework

#### 1. Azure Cost Management Queries

Use the `azure-mcp` server to query Azure Cost Management:
- Filter by subscription, resource group, tag, or service name.
- Group by `ResourceType`, `ResourceGroupName`, `MeterCategory`, or `Tags`.
- Compare current month vs previous month to spot anomalies.
- Use the `microsoft-learn` MCP to reference: https://learn.microsoft.com/azure/cost-management-billing/

#### 2. Budget Alerts

Create budgets with multi-threshold alerts:

```bicep
resource budget 'Microsoft.Consumption/budgets@2021-10-01' = {
  name: 'budget-${workload}-${env}-monthly'
  properties: {
    timePeriod: { startDate: '2024-01-01' }
    timeGrain: 'Monthly'
    amount: budgetAmount
    category: 'Cost'
    notifications: {
      actual80: {
        enabled: true
        operator: 'GreaterThanOrEqualTo'
        threshold: 80
        contactEmails: contactEmails
      }
      actual100: {
        enabled: true
        operator: 'GreaterThanOrEqualTo'
        threshold: 100
        contactEmails: contactEmails
      }
      forecasted110: {
        enabled: true
        operator: 'GreaterThanOrEqualTo'
        threshold: 110
        thresholdType: 'Forecasted'
        contactEmails: contactEmails
      }
    }
  }
}
```

#### 3. Reserved Instances & Savings Plans

| Option | Commitment | Discount vs PAYG | Best for |
|---|---|---|---|
| 1-year Reserved Instance | 1 year | ~40% | Stable, predictable workloads |
| 3-year Reserved Instance | 3 years | ~60% | Long-lived production workloads |
| 1-year Compute Savings Plan | 1 year | ~17% | Flexible compute (any VM family/region) |
| 3-year Compute Savings Plan | 3 years | ~33% | Flexible compute, long commitment |
| Spot VMs | None | up to 90% | Fault-tolerant, interruptible workloads |

**Decision rule**: use Reserved Instances for specific VM SKUs in a fixed region; use Savings Plans for diverse or frequently-changing VM types.

#### 4. Azure Advisor Cost Recommendations

Query Azure Advisor for cost recommendations via `azure-mcp`:
- Right-size or shut down underutilised VMs (< 5% CPU average over 14 days).
- Delete unattached managed disks.
- Right-size ExpressRoute circuits.
- Remove idle App Service plans.
- Convert Standard disks to lower tiers where IOPS allows.

#### 5. Right-Sizing

For each resource type, apply these sizing rules:

| Resource | Signal | Action |
|---|---|---|
| Virtual Machines | CPU < 10% avg, Memory < 40% avg | Downsize to next smaller SKU or B-series |
| Azure SQL Database | DTU < 20% avg | Scale down or switch to serverless |
| App Service Plans | CPU < 20% avg | Scale down plan tier |
| AKS Node Pools | Node CPU requests < 30% | Reduce node count or VM size |
| Azure Cache for Redis | Memory usage < 30% | Downgrade cache tier |

#### 6. Auto-Shutdown, Dev/Test Pricing & B-Series Burstable

- Enable **auto-shutdown** on all non-production VMs (e.g., 19:00 local time, restart at 08:00).
- Apply **Dev/Test pricing** via Visual Studio subscriptions for eligible workloads (up to 60% saving).
- Use **B-series burstable VMs** (`Standard_B2s`, `Standard_B4ms`) for workloads with occasional CPU bursts (dev, CI agents, small APIs).

```terraform
resource "azurerm_dev_test_global_vm_shutdown_schedule" "auto_shutdown" {
  virtual_machine_id = azurerm_linux_virtual_machine.vm.id
  location           = var.location
  enabled            = true
  daily_recurrence_time = "1900"
  timezone           = "UTC"
  notification_settings { enabled = false }
}
```

#### 7. Tagging for Cost Allocation

Enforce these tags to enable granular cost reporting:

| Tag | Purpose |
|---|---|
| `CostCenter` | Finance charge-back code |
| `Environment` | dev / staging / prod |
| `Owner` | Team responsible for costs |
| `Project` | Business project or workstream |
| `Expiry` | ISO date after which resource should be reviewed |

#### 8. KQL Queries Against Cost Exports

When cost data is exported to Log Analytics, use KQL to analyse trends:

```kql
// Top 10 costliest resource groups this month
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.COSTMANAGEMENT"
| summarize TotalCost = sum(todouble(column_ifexists("PreTaxCost_d", 0)))
    by ResourceGroup
| top 10 by TotalCost desc
| render barchart

// Daily spend trend for the last 30 days
Usage
| where TimeGenerated > ago(30d)
| summarize DailyCost = sum(Quantity * UnitPrice) by bin(TimeGenerated, 1d)
| render timechart
```

### Preferred MCP Servers

- `azure-mcp` — query Cost Management, list Advisor recommendations, inspect resource utilisation.
- `microsoft-learn` — retrieve FinOps documentation and pricing calculator guidance.

### Output Format

Provide all recommendations in this structure:

| # | Recommendation | Monthly Saving (USD est.) | Effort | Priority |
|---|---|---|---|---|
| 1 | … | $X | Low/Med/High | P1/P2/P3 |

Followed by:
- Implementation steps with Azure CLI or IaC code
- Azure CLI commands to apply the change
- Validation steps to confirm saving


---

## 🎓 Teaching Mode Behavior

If Teaching Mode is **ON** (see `.github/copilot-instructions.md`), after producing the primary artifact, also emit the six teaching sections:

1. **Why this design?** — 2–4 bullets mapping decisions to Azure Well-Architected Framework pillar(s) and/or CAF principles.
2. **Trade-offs considered** — alternatives evaluated and why the chosen path won.
3. **What could go wrong** — top 1–3 failure modes / misconfigurations and how to detect them.
4. **Learn more** — 2–3 links to Microsoft Learn / CAF / WAF docs (use the `microsoft-learn` MCP if available).
5. **Try it yourself** — a short hands-on exercise or `az` / `terraform` / `bicep` command the engineer can run.
6. **Glossary** — define Azure acronyms (NSG, UDR, PE, MI, LAW, etc.) on first use in that response.

If Teaching Mode is **OFF** (default), skip these sections entirely. Output is minimal as today.
