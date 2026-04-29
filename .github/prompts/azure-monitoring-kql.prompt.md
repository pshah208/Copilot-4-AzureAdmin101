---
mode: 'agent'
description: 'Author KQL queries, Azure Monitor alerts, Workbooks, and observability strategies for Azure workloads covering performance, reliability, and security use cases.'
applyTo: '**/*.kql,**/*kql*,**/monitoring/**,**/workbooks/**'
---

# Azure Monitoring, KQL & Observability Skill

## Description

Use this skill to write KQL queries, design Azure Monitor alert rules, author Workbooks, and build a comprehensive observability strategy for Azure workloads. Covers performance, reliability, and security scenarios across the full Azure Monitor data platform.

---

## Prompt

You are an Azure observability engineer. Help me with the following monitoring task:

**Task**: ${input:task:Describe the monitoring requirement – e.g. "Create KQL queries and alert rules to detect VM CPU saturation, failed deployments in Activity Log, and failed sign-in spikes in Entra ID"}
**Workspace / resource scope**: ${input:scope:Log Analytics workspace name or resource group}
**Alert severity threshold**: ${input:severity:e.g. Sev1 for critical, Sev2 for warning}

### KQL Fundamentals

#### Core Operators

| Operator | Purpose | Example |
|---|---|---|
| `where` | Filter rows | `where Level == "Error"` |
| `project` | Select/rename columns | `project TimeGenerated, Message, Level` |
| `extend` | Add computed columns | `extend Duration = EndTime - StartTime` |
| `summarize` | Aggregate | `summarize Count = count() by bin(TimeGenerated, 5m)` |
| `join` | Combine tables | `T1 \| join kind=inner T2 on $left.Id == $right.Id` |
| `let` | Define variable or function | `let threshold = 90;` |
| `render` | Visualise | `render timechart` |
| `top` | Top N rows | `top 10 by Count desc` |
| `parse` | Extract from strings | `parse Message with * "error=" ErrorCode " " *` |
| `mv-expand` | Expand dynamic arrays | `mv-expand tags` |

#### Common Log Analytics Tables

| Table | Description |
|---|---|
| `AzureActivity` | Azure control-plane operations (deployments, RBAC changes) |
| `AzureDiagnostics` | Diagnostic logs from multiple resource types |
| `AzureMetrics` | Platform metrics forwarded to Log Analytics |
| `AppTraces` | Application Insights trace telemetry |
| `AppRequests` | Application Insights HTTP request telemetry |
| `AppExceptions` | Application Insights exception telemetry |
| `Heartbeat` | Agent health check every 60 seconds |
| `Perf` | Performance counters (CPU, memory, disk) |
| `Syslog` | Linux system log |
| `SecurityEvent` | Windows Security event log |
| `SigninLogs` | Entra ID interactive sign-in logs |
| `AuditLogs` | Entra ID audit events |
| `ContainerLog` | AKS container stdout/stderr |
| `KubeEvents` | Kubernetes events |

### KQL Recipe Library

#### VM CPU Saturation (> 90% for 5+ minutes)

```kql
Perf
| where ObjectName == "Processor" and CounterName == "% Processor Time"
| where InstanceName == "_Total"
| where TimeGenerated > ago(1h)
| summarize AvgCPU = avg(CounterValue) by Computer, bin(TimeGenerated, 5m)
| where AvgCPU > 90
| project TimeGenerated, Computer, AvgCPU
| order by TimeGenerated desc
```

#### Failed Azure Deployments (Activity Log)

```kql
AzureActivity
| where ActivityStatusValue == "Failure"
| where OperationNameValue startswith "Microsoft.Resources/deployments"
| where TimeGenerated > ago(24h)
| project TimeGenerated, Caller, ResourceGroup, OperationNameValue, Properties
| order by TimeGenerated desc
```

#### Failed Sign-In Spikes (Entra ID)

```kql
SigninLogs
| where TimeGenerated > ago(1h)
| where ResultType != "0"
| summarize FailedSignIns = count() by UserPrincipalName, bin(TimeGenerated, 5m)
| where FailedSignIns > 10
| render timechart
```

#### Application Error Rate (Application Insights)

```kql
AppRequests
| where TimeGenerated > ago(30m)
| summarize
    Total    = count(),
    Failed   = countif(Success == false)
    by bin(TimeGenerated, 1m), AppRoleName
| extend ErrorRate = round(todouble(Failed) / todouble(Total) * 100, 2)
| where ErrorRate > 5
| render timechart
```

#### AKS Pod Restarts (Container Insights)

```kql
KubePodInventory
| where TimeGenerated > ago(1h)
| where PodRestartCount > 3
| project TimeGenerated, Namespace, PodName = Name, PodRestartCount, ContainerStatus
| order by PodRestartCount desc
```

#### Storage Account Throttling

```kql
AzureMetrics
| where ResourceProvider == "Microsoft.Storage"
| where MetricName == "Transactions"
| where DimensionValue == "ServerBusy"
| summarize ThrottledRequests = sum(Total) by Resource, bin(TimeGenerated, 5m)
| where ThrottledRequests > 0
| render timechart
```

### Alert Rule Design

#### Alert Types

| Alert Type | When to use | Key settings |
|---|---|---|
| **Metric alert** | Platform metrics (CPU %, DTU, request count) | Static or dynamic threshold, evaluation frequency |
| **Log alert** | Custom KQL queries against Log Analytics | Query result count or metric measurement |
| **Activity Log alert** | Control-plane events (delete, RBAC change, health) | Operations filter, resource scope |

#### Dynamic Thresholds

Use dynamic thresholds for metrics with seasonal patterns (e.g., daily CPU cycles, weekly traffic peaks):

```bicep
criteria: {
  'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
  allOf: [
    {
      criterionType: 'DynamicThresholdCriterion'
      metricName: 'Percentage CPU'
      operator: 'GreaterThan'
      alertSensitivity: 'Medium'
      failingPeriods: {
        numberOfEvaluationPeriods: 4
        minFailingPeriodsToAlert: 3
      }
    }
  ]
}
```

#### Action Groups & Notification Routing

```bicep
resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: 'ag-${workload}-${env}-critical'
  location: 'global'
  properties: {
    groupShortName: 'CriticalAG'
    enabled: true
    emailReceivers: [
      { name: 'OnCallEmail'; emailAddress: onCallEmail; useCommonAlertSchema: true }
    ]
    webhookReceivers: [
      { name: 'TeamsWebhook'; serviceUri: teamsWebhookUrl; useCommonAlertSchema: true }
    ]
  }
}
```

Route by severity:
- **Sev0/Sev1**: PagerDuty webhook + email to on-call team
- **Sev2**: Teams/Slack webhook + email to dev team
- **Sev3/Sev4**: Email only to monitoring alias

### Workbooks & Dashboards

When authoring Azure Monitor Workbooks:
- Use **Parameters** (time range, subscription, resource group) at the top.
- Organise into tabs: Overview → Reliability → Performance → Security.
- Include **KPI tiles** (metric, log count) before detailed charts.
- Use `render barchart` and `render timechart` in KQL for inline visualisations.
- Export Workbook ARM JSON for IaC deployment.

### Preferred MCP Servers

- `azure-mcp` — run KQL queries against Log Analytics, list alert rules, inspect metrics.
- `microsoft-learn` — retrieve KQL documentation and Azure Monitor best practices.

### Output Format

- KQL query in a ` ```kql ` code block with inline comments explaining each step
- Alert rule definition in Bicep or Terraform
- Action group configuration
- Estimated query cost (Log Analytics data processed)
- Links to relevant Microsoft Learn documentation


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
