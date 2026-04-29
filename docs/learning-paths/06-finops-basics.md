# 06 – FinOps Basics: Cost Management, Tagging, and Budgets

## Objectives

By the end of this track you will be able to:

- [ ] Explain the core FinOps principles and the Azure Cost Management toolset
- [ ] Design a tagging strategy for cost allocation and enforce it via Azure Policy
- [ ] Create budget alerts at subscription and resource group scope
- [ ] Identify cost optimisation quick wins using Azure Advisor
- [ ] Right-size compute resources using utilisation data

---

## Concepts

### What Is FinOps?

FinOps (Financial Operations) is a practice where engineering, finance, and business teams collaborate to maximise the value of cloud spending. The FinOps Foundation defines three phases:

| Phase | Activity |
|---|---|
| **Inform** | Gain visibility — who is spending what, where, and why |
| **Optimise** | Reduce waste — right-size, reserve, schedule, and retire |
| **Operate** | Govern continuously — budgets, anomaly detection, showback/chargeback |

Azure Cost Management + Billing is the primary tool for all three phases.

### Azure Cost Management Fundamentals

**Cost analysis**: Explore spend by subscription, resource group, tag, service type, or location. Available in the Azure portal under Cost Management + Billing.

**Cost dimensions**:

| Dimension | What it groups by |
|---|---|
| `ResourceGroupName` | Which resource group owns the cost |
| `ResourceType` | Service type (e.g., `microsoft.compute/virtualmachines`) |
| `MeterCategory` | Billing meter (e.g., "Virtual Machines", "Storage") |
| `Tags` | Any tag value (requires tagging policy enforcement) |

**Granularity options**: Daily, Monthly, Accumulate-by-month.

### Tagging Strategy for Cost Allocation

Tags are the **foundation of FinOps**. Without consistent tags, cost allocation is guesswork.

Enforce these tags on all resources via Azure Policy (this repo's policy module does this):

| Tag key | Purpose | Example value |
|---|---|---|
| `Environment` | Separate prod vs. non-prod costs | `prod`, `staging`, `dev` |
| `CostCenter` | Finance charge-back code | `CC-1234` |
| `Owner` | Team responsible for the resource | `platform-team` |
| `CreatedBy` | Who or what created it | `terraform`, `johndoe@example.com` |
| `Project` | Business project or workstream | `ecommerce-replatform` |
| `Expiry` | When the resource should be reviewed | `2025-12-31` |

**Why enforce via Policy?** Without a `Deny` policy on missing tags, tags are optional and consistently inconsistent. The repo's policy module uses `Deny` effect — no resource can be created without the required tags.

### Reserved Instances vs. Savings Plans vs. Spot

| Option | Commitment | Discount vs. PAYG | Best for |
|---|---|---|---|
| **1-year Reserved Instance** | 1 year, specific VM SKU + region | ~40% | Stable, predictable workloads |
| **3-year Reserved Instance** | 3 years, specific VM SKU + region | ~60% | Long-lived production workloads |
| **1-year Compute Savings Plan** | 1 year, any VM family/region | ~17% | Diverse or frequently-changing VM types |
| **3-year Compute Savings Plan** | 3 years, any VM family/region | ~33% | Long commitment, flexible compute |
| **Spot VMs** | None (evictable) | up to 90% | Fault-tolerant, interruptible (CI/CD, batch, dev) |

**Decision rule**:
- Specific VM SKU in a fixed region for 1–3 years → **Reserved Instance**
- Diverse VM types or frequent SKU changes → **Savings Plan**
- Can tolerate eviction → **Spot**

### Azure Advisor Cost Recommendations

Azure Advisor analyses your environment and surfaces cost recommendations automatically:

| Recommendation type | Typical saving |
|---|---|
| Right-size or shut down underutilised VMs | Medium–high |
| Delete unattached managed disks | Low (but zero-effort) |
| Right-size ExpressRoute circuits | High (ExpressRoute is expensive) |
| Buy Reserved Instances for consistent usage | High (pay-as-you-go premium) |
| Remove idle App Service plans | Low |

Query Advisor recommendations via CLI:
```bash
az advisor recommendation list \
  --category Cost \
  --output table
```

---

## Repo Code Walkthrough

### Tags Enforced by Policy Module

**File**: `terraform/landing-zone/modules/policy/main.tf`

The policy module deploys a `Deny` policy requiring four tags on all resources in the assigned scope. This is the enforcement layer for FinOps tagging.

```hcl
# The policy blocks creation of any resource missing these tags:
# - Environment
# - CostCenter
# - Owner
# - CreatedBy
```

All Terraform resources in this repo pass tags via the root-level `tags` variable, which flows through every module:

**File**: `terraform/landing-zone/variables.tf`

```hcl
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "dev"
    CostCenter  = "platform"
    Owner       = "platform-team"
    CreatedBy   = "terraform"
  }
}
```

### Auto-Shutdown for Non-Production VMs

The cost optimisation skill (`.github/prompts/azure-cost-optimization.prompt.md`) includes a Terraform resource for auto-shutdown. For any non-production VM, add:

```hcl
resource "azurerm_dev_test_global_vm_shutdown_schedule" "auto_shutdown" {
  virtual_machine_id    = azurerm_linux_virtual_machine.vm.id
  location              = var.location
  enabled               = true
  daily_recurrence_time = "1900"
  timezone              = "UTC"
  notification_settings { enabled = false }
}
```

A VM running 24/7 at PAYG costs ~3× what it costs running 10 hours/day (08:00–18:00) on weekdays.

### Budget Alerts (Bicep)

The cost optimisation prompt includes a budget resource. Here is the pattern for a monthly budget with three thresholds (80%, 100%, 110% forecast):

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

---

## Checkpoint Questions

1. Azure Advisor recommends right-sizing a VM from `Standard_D4s_v5` to `Standard_D2s_v5`. What information would you want before accepting the recommendation?
2. You export cost data to a Storage Account. How would you query it with KQL to find the top 5 most expensive resource groups this month?
3. Why does a `Deny` policy on tags save money, not just governance overhead?
4. A team complains their resource group is being charged for a VM they deleted. What is the most likely explanation and how do you investigate?

<details>
<summary>Answers (reveal after attempting)</summary>

1. CPU and memory utilisation trends over 14–30 days (not just averages — check P95/P99 spikes), application performance metrics (response time, error rate), and whether the workload has predictable peaks (e.g., month-end batch jobs) that would be impacted by downsizing.
2. Query the exported cost data (CSV or Parquet in Storage) ingested into Log Analytics:
   ```kql
   AzureDiagnostics
   | where ResourceProvider == "MICROSOFT.COSTMANAGEMENT"
   | summarize TotalCost = sum(todouble(column_ifexists("PreTaxCost_d", 0))) by ResourceGroup
   | top 5 by TotalCost desc
   ```
3. Untagged resources cannot be attributed to a cost center or team — finance cannot charge back accurately, so all costs land on a shared "unknown" bucket. With no accountability, teams have no incentive to optimise. Tags + policy create **financial ownership** at the team level.
4. Managed Disks and NICs associated with a VM persist after the VM is deleted if not explicitly deleted. Check for orphaned `Microsoft.Compute/disks` and `Microsoft.Network/networkInterfaces` in the resource group:
   ```bash
   az disk list --resource-group <rg> --query "[?diskState!='Attached'].[name,diskSizeGb]" -o table
   ```

</details>

---

## Hands-On Exercise

Set up a budget alert for a resource group and verify it fires:

```bash
# 1. Create a budget at resource group scope
RG_ID=$(az group show --name rg-connectivity-dev-eastus-001 --query id -o tsv)

az consumption budget create \
  --budget-name "budget-connectivity-dev-monthly" \
  --amount 500 \
  --time-grain Monthly \
  --start-date 2024-01-01 \
  --end-date 2026-12-31 \
  --resource-group rg-connectivity-dev-eastus-001 \
  --notifications '[
    {
      "enabled": true,
      "operator": "GreaterThanOrEqualTo",
      "threshold": 80,
      "contactEmails": ["yourname@example.com"],
      "thresholdType": "Actual"
    },
    {
      "enabled": true,
      "operator": "GreaterThanOrEqualTo",
      "threshold": 100,
      "contactEmails": ["yourname@example.com"],
      "thresholdType": "Forecasted"
    }
  ]'

# 2. Check current spend vs. budget
az consumption budget show \
  --budget-name "budget-connectivity-dev-monthly" \
  --resource-group rg-connectivity-dev-eastus-001 \
  --query "{Amount:amount,CurrentSpend:currentSpend.amount,ForecastedSpend:forecastSpend.amount}"

# 3. View Azure Advisor cost recommendations for the subscription
az advisor recommendation list \
  --category Cost \
  --query "[].{Impact:impact,ShortDescription:shortDescription.solution,ResourceId:resourceMetadata.resourceId}" \
  --output table
```

---

## Further Reading

| Topic | Link |
|---|---|
| Azure Cost Management overview | https://learn.microsoft.com/azure/cost-management-billing/cost-management-billing-overview |
| FinOps for Azure | https://learn.microsoft.com/azure/cost-management-billing/finops/ |
| Reserved Instances | https://learn.microsoft.com/azure/cost-management-billing/reservations/save-compute-costs-reservations |
| Azure Savings Plans | https://learn.microsoft.com/azure/cost-management-billing/savings-plan/savings-plan-compute-overview |
| Azure Advisor cost recommendations | https://learn.microsoft.com/azure/advisor/advisor-cost-recommendations |
| Tagging best practices | https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-tagging |
