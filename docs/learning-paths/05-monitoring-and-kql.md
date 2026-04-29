# 05 – Monitoring, Log Analytics, and KQL

## Objectives

By the end of this track you will be able to:

- [ ] Explain the Azure Monitor data platform and where different log types land
- [ ] Write KQL queries to answer operational questions about your landing zone
- [ ] Design alert rules (metric, log, activity log) with appropriate severity and action groups
- [ ] Understand the Log Analytics workspace (LAW) deployed in this repo and its diagnostic scope
- [ ] Build a basic Azure Monitor Workbook tab

---

## Concepts

### The Azure Monitor Data Platform

Azure Monitor is the umbrella service for all observability in Azure. It has three pillars:

| Pillar | What it collects | Where it's stored |
|---|---|---|
| **Metrics** | Numeric time-series (CPU %, byte count) | Azure Monitor Metrics (15 months) |
| **Logs** | Structured events, traces, diagnostics | Log Analytics Workspace (configurable retention) |
| **Traces** | Distributed request tracing | Application Insights (linked to LAW) |

Diagnostic settings forward platform logs and metrics from Azure resources into a **Log Analytics Workspace (LAW)**. The hub module in this repo deploys a central LAW and configures diagnostic settings on the Azure Firewall to stream logs to it.

### Key Log Analytics Tables

| Table | What's in it | Use case |
|---|---|---|
| `AzureActivity` | Azure control-plane operations | Audit deployments, RBAC changes, deletes |
| `AzureFirewallApplicationRule` | Firewall app rule hits | Detect blocked traffic, allowed URLs |
| `AzureFirewallNetworkRule` | Firewall network rule hits | East-west traffic audit |
| `Perf` | VM performance counters (CPU, memory, disk) | Capacity planning, alerts |
| `SecurityEvent` | Windows Security event log | Identity & access auditing |
| `SigninLogs` | Entra ID interactive sign-ins | Failed login detection |
| `AzureMetrics` | Platform metrics forwarded to LAW | Trend analysis on non-alertable metrics |
| `Heartbeat` | Agent health (every 60 s) | VM connectivity monitoring |

### KQL Fundamentals

KQL (Kusto Query Language) reads left-to-right as a pipeline. Each `|` pipes the result of one operator into the next.

```kql
TableName                               // Start with a table
| where TimeGenerated > ago(1h)         // Filter rows
| where Level == "Error"                // Additional filter
| project TimeGenerated, Message, Level // Select columns
| summarize Count = count() by Level   // Aggregate
| order by Count desc                   // Sort
| take 10                               // Limit results
```

Essential operators:

| Operator | Purpose |
|---|---|
| `where` | Filter rows by condition |
| `project` | Select / rename columns |
| `extend` | Add computed columns |
| `summarize` | Aggregate (count, avg, sum, percentile) |
| `join` | Combine two tables |
| `let` | Define a variable or function |
| `render` | Visualise (timechart, barchart, piechart) |
| `parse` | Extract fields from unstructured strings |
| `mv-expand` | Expand dynamic arrays into rows |

---

## Repo Code Walkthrough

### Log Analytics Workspace

**Terraform**: `azurerm_log_analytics_workspace` in `modules/hub-network/main.tf`

```hcl
resource "azurerm_log_analytics_workspace" "hub" {
  name                = "law-hub-${var.environment}-${var.location}-001"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 90
  tags                = var.tags
}
```

- `PerGB2018` SKU: pay-per-GB ingested (no commitment tier required for moderate volumes)
- `retention_in_days = 90`: 90 days interactive query + configurable long-term archive
- Single workspace for all hub resources = unified query scope across networking, firewall, security

**Bicep**: `bicep/landing-zone/modules/log-analytics.bicep` — equivalent `Microsoft.OperationalInsights/workspaces@2022-10-01`

### Firewall Diagnostic Settings

```hcl
resource "azurerm_monitor_diagnostic_setting" "firewall" {
  name                       = "diag-firewall"
  target_resource_id         = azurerm_firewall.hub.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.hub.id

  enabled_log { category = "AzureFirewallApplicationRule" }
  enabled_log { category = "AzureFirewallNetworkRule"      }
  enabled_log { category = "AzureFirewallDnsProxy"         }

  metric { category = "AllMetrics" enabled = true }
}
```

This configuration sends all Firewall log categories and metrics to the central LAW. Other resources (VMs, NSGs) require their own diagnostic settings — enforced by the DINE policy in the policy module.

---

## KQL Recipe Library

### 1. Recent Firewall Blocks

```kql
AzureFirewallNetworkRule
| where TimeGenerated > ago(1h)
| where Action == "Deny"
| project TimeGenerated, SourceIP, DestinationIP, DestinationPort, Protocol
| order by TimeGenerated desc
| take 50
```

### 2. Failed Azure Deployments (Last 24 Hours)

```kql
AzureActivity
| where TimeGenerated > ago(24h)
| where ActivityStatusValue == "Failure"
| where OperationNameValue startswith "Microsoft.Resources/deployments"
| project TimeGenerated, Caller, ResourceGroup, OperationNameValue
| order by TimeGenerated desc
```

### 3. VM CPU Over 90% (Last Hour)

```kql
Perf
| where ObjectName == "Processor" and CounterName == "% Processor Time"
| where InstanceName == "_Total"
| where TimeGenerated > ago(1h)
| summarize AvgCPU = avg(CounterValue) by Computer, bin(TimeGenerated, 5m)
| where AvgCPU > 90
| render timechart
```

### 4. Policy Non-Compliance Events

```kql
AzureActivity
| where TimeGenerated > ago(7d)
| where OperationNameValue == "Microsoft.Authorization/policies/audit/action"
| project TimeGenerated, ResourceGroup, ResourceId, Properties
| order by TimeGenerated desc
```

### 5. Entra ID Failed Sign-Ins Spike

```kql
SigninLogs
| where TimeGenerated > ago(1h)
| where ResultType != "0"
| summarize FailedCount = count() by UserPrincipalName, bin(TimeGenerated, 5m)
| where FailedCount > 10
| render timechart
```

---

## Alert Rule Design

### Alert Rule Types

| Type | Based on | Example use case |
|---|---|---|
| **Metric alert** | Platform metric time-series | VM CPU > 90% for 5 min |
| **Log alert** | KQL query result | More than 5 deployment failures in 1 hour |
| **Activity log alert** | Specific control-plane operations | Any `delete` operation on Key Vault |

### Severity Mapping

| Severity | Meaning | Typical action |
|---|---|---|
| Sev0 | Critical — service down | Page on-call immediately |
| Sev1 | Error — degraded service | Page on-call within 15 min |
| Sev2 | Warning — potential issue | Notify dev team via Teams/Slack |
| Sev3/Sev4 | Informational | Email digest |

### Action Group Pattern

An **action group** defines what happens when an alert fires. One action group per severity tier:

```bicep
resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: 'ag-${workload}-sev1-${env}'
  location: 'global'
  properties: {
    groupShortName: 'Sev1AG'
    enabled: true
    emailReceivers: [
      { name: 'OnCall'; emailAddress: onCallEmail; useCommonAlertSchema: true }
    ]
  }
}
```

---

## Checkpoint Questions

1. You want to alert when more than 10 firewall DENY events occur within 5 minutes. What type of alert rule do you use?
2. What is the difference between `AzureFirewallNetworkRule` and `AzureFirewallApplicationRule` tables?
3. A query returns no results but you expect data. What are the three most likely causes?
4. Why use a single central Log Analytics workspace instead of one per spoke?

<details>
<summary>Answers (reveal after attempting)</summary>

1. A **log alert** rule running the `AzureFirewallNetworkRule | where Action == "Deny"` KQL query with a `count > 10` threshold over a 5-minute window.
2. `AzureFirewallNetworkRule` logs L4 (IP/port) rule hits. `AzureFirewallApplicationRule` logs L7 (FQDN/URL) rule hits (requires Premium SKU for TLS inspection). If you block `10.1.0.5` to port 80, it appears in NetworkRule. If you block `*.evil.com`, it appears in ApplicationRule.
3. (a) Diagnostic settings aren't configured on the resource — no data is flowing to the LAW; (b) the time range filter (`ago(1h)`) is too narrow; (c) the workspace ID referenced in the query doesn't match where the data is actually being sent.
4. A central LAW reduces cost (single retention policy, no per-workspace overhead), enables cross-subscription correlation queries, simplifies alert rule management (fewer workspaces to maintain), and gives security teams a single pane of glass.

</details>

---

## Hands-On Exercise

Write and test a KQL query to detect all resource deletions in the last 7 days and create a log alert:

```bash
# 1. Open Log Analytics in the portal and run this query
# (or use Azure CLI with az monitor log-analytics query)

az monitor log-analytics query \
  --workspace "<your-LAW-workspace-id>" \
  --analytics-query "
AzureActivity
| where TimeGenerated > ago(7d)
| where OperationNameValue endswith '/delete'
| where ActivityStatusValue == 'Success'
| project TimeGenerated, Caller, ResourceGroup, OperationNameValue, ResourceId
| order by TimeGenerated desc
  " \
  --output table

# 2. Create a log alert rule for future delete operations
az monitor scheduled-query create \
  --name "alert-resource-deletions" \
  --resource-group rg-monitoring-dev-eastus-001 \
  --scopes "<your-LAW-resource-id>" \
  --condition "count > 0" \
  --condition-query "
AzureActivity
| where OperationNameValue endswith '/delete'
| where ActivityStatusValue == 'Success'
  " \
  --evaluation-frequency 5m \
  --window-size 5m \
  --severity 2 \
  --action-groups "<your-action-group-resource-id>" \
  --description "Alert on any successful resource deletion"
```

**Expected result**: The query returns a table of delete operations. The alert fires within 5 minutes of the next deletion.

---

## Further Reading

| Topic | Link |
|---|---|
| Azure Monitor overview | https://learn.microsoft.com/azure/azure-monitor/overview |
| KQL quick reference | https://learn.microsoft.com/azure/data-explorer/kql-quick-reference |
| Log Analytics workspace | https://learn.microsoft.com/azure/azure-monitor/logs/log-analytics-workspace-overview |
| Alert rules in Azure Monitor | https://learn.microsoft.com/azure/azure-monitor/alerts/alerts-overview |
| Azure Firewall logs | https://learn.microsoft.com/azure/firewall/logs-and-metrics |
| Azure Monitor Workbooks | https://learn.microsoft.com/azure/azure-monitor/visualize/workbooks-overview |
