# 🎓 Learning with Copilot for Azure Administration

> **Philosophy**: "Give a person a fish and you feed them for a day. Teach a person to fish and you feed them for a lifetime."
>
> This repo does both. Every Copilot skill produces ready-to-deploy Azure artifacts — and when you want to understand *why*, **Teaching Mode** turns each interaction into a structured learning session.

---

## What Is Teaching Mode?

Teaching Mode is an **opt-in** feature that instructs Copilot to accompany every Azure artifact (IaC, diagram, policy, KQL, etc.) with six structured learning sections:

| Section | What you get |
|---|---|
| 🏗️ **Why this design?** | 2–4 bullets mapping decisions to Well-Architected Framework pillar(s) / CAF principles |
| ⚖️ **Trade-offs considered** | Alternatives evaluated and why the chosen path won |
| ⚠️ **What could go wrong** | Top 1–3 failure modes and how to detect them |
| 📖 **Learn more** | 2–3 links to Microsoft Learn / CAF / WAF docs |
| 🧪 **Try it yourself** | A short hands-on exercise or runnable `az` / `terraform` / `bicep` command |
| 📘 **Glossary** | Azure acronyms defined on first use (NSG, UDR, PE, MI, LAW, …) |

Teaching Mode is **OFF by default**. Your normal workflow is unaffected until you turn it on.

---

## Turning Teaching Mode On and Off

Say any of these phrases in GitHub Copilot Chat (case-insensitive):

### Activate

| Phrase | Effect |
|---|---|
| `teach mode on` | ON for the rest of the conversation |
| `enable teaching mode` | ON for the rest of the conversation |
| `/teach on` | ON for the rest of the conversation |
| `explain as you build` | **One-shot** — applies to the next response only, then auto-disables |

### Deactivate

| Phrase | Effect |
|---|---|
| `teach mode off` | OFF for the rest of the conversation |
| `disable teaching mode` | OFF for the rest of the conversation |
| `/teach off` | OFF for the rest of the conversation |
| `just do it` | Silences teaching for the **current response only** |

Copilot confirms the change inline:
- `✅ Teaching Mode: ON`
- `Teaching Mode: OFF`

---

## 30-Second First Session

Try this right now in GitHub Copilot Chat:

```
teach mode on

Design a hub-and-spoke landing zone for a dev/test environment with 2 spoke subscriptions.
```

Copilot will produce the architecture overview **plus** a full explanation of why hub-and-spoke was chosen, what alternatives exist, common pitfalls, Microsoft Learn links, and a hands-on lab command to run.

When you're done exploring, say `teach mode off` to return to the normal concise workflow.

---

## Deep-Dive Teaching: Explain an Existing File

The [`azure-teaching-mode.prompt.md`](.github/prompts/azure-teaching-mode.prompt.md) skill lets you point Copilot at any file in this repo for a detailed walkthrough — no `teach mode on` required:

```
#file:.github/prompts/azure-teaching-mode.prompt.md

Walk me through terraform/landing-zone/modules/hub-network/main.tf
```

Copilot will explain each resource block, map it to CAF/WAF principles, surface failure modes, and produce a step-by-step lab to reproduce the module from scratch with checkpoint questions.

---

## Learning Tracks

Work through these tracks in order, or jump to whichever topic you need. Each track uses the actual Terraform and Bicep code in this repo as the learning material.

| # | Track | File | What you'll learn |
|---|---|---|---|
| 01 | Landing Zone Fundamentals | [`docs/learning-paths/01-landing-zone-fundamentals.md`](docs/learning-paths/01-landing-zone-fundamentals.md) | CAF, management groups, subscriptions, hub-spoke model |
| 02 | IaC: Terraform vs. Bicep | [`docs/learning-paths/02-iac-with-terraform-vs-bicep.md`](docs/learning-paths/02-iac-with-terraform-vs-bicep.md) | When to choose which, comparing this repo's two implementations |
| 03 | Networking: Hub-Spoke | [`docs/learning-paths/03-networking-hub-spoke.md`](docs/learning-paths/03-networking-hub-spoke.md) | VNets, subnets, peering, private endpoints, DNS |
| 04 | Policy & Governance | [`docs/learning-paths/04-policy-and-governance.md`](docs/learning-paths/04-policy-and-governance.md) | Azure Policy, initiatives, RBAC, management groups |
| 05 | Monitoring & KQL | [`docs/learning-paths/05-monitoring-and-kql.md`](docs/learning-paths/05-monitoring-and-kql.md) | Log Analytics, KQL fundamentals, alerts, Workbooks |
| 06 | FinOps Basics | [`docs/learning-paths/06-finops-basics.md`](docs/learning-paths/06-finops-basics.md) | Cost management, tagging, budgets, Reserved Instances |

Each track follows the same structure:

> **Objectives → Concepts → Repo Code Walkthrough → Checkpoint Questions → Hands-On Exercise → Further Reading**

---

## Skills Reference

All Copilot skills in this repo live in `.github/prompts/`. Invoke any skill by attaching it as context in Copilot Chat:

```
#file:.github/prompts/azure-landing-zone.prompt.md

Design a landing zone for a retail company with PCI-DSS requirements.
```

| Skill | File | Teaching Mode aware? |
|---|---|---|
| Azure Landing Zone | `azure-landing-zone.prompt.md` | ✅ |
| Azure Architecture Design | `azure-architecture-design.prompt.md` | ✅ |
| Azure Troubleshooting | `azure-troubleshooting.prompt.md` | ✅ |
| Azure Policy & Governance | `azure-policy-governance.prompt.md` | ✅ |
| Azure Cost Optimisation | `azure-cost-optimization.prompt.md` | ✅ |
| Azure Monitoring & KQL | `azure-monitoring-kql.prompt.md` | ✅ |
| Terraform & Bicep Deployment | `terraform-bicep-deployment.prompt.md` | ✅ |
| Draw.io Architecture Diagram | `drawio-architecture.prompt.md` | ✅ |
| Draw.io Icon Verification | `drawio-icon-verification.prompt.md` | ✅ |
| Draw.io Export & Publish | `drawio-export-publish.prompt.md` | ✅ |
| **Teaching Mode Deep-Dive** | `azure-teaching-mode.prompt.md` | Always on (by design) |

---

## Presentation Deck

The repo includes a PowerPoint deck with an overview of all capabilities:

📎 [`GitHub Copilot CLI Your AI-Powered Azure Administration Companion.pptx`](GitHub%20Copilot%20CLI%20Your%20AI-Powered%20Azure%20Administration%20Companion.pptx)

---

## Further Reading

| Resource | Link |
|---|---|
| Microsoft Cloud Adoption Framework | https://learn.microsoft.com/azure/cloud-adoption-framework/ |
| Azure Landing Zones | https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/ |
| Azure Well-Architected Framework | https://learn.microsoft.com/azure/well-architected/ |
| Azure Architecture Center | https://learn.microsoft.com/azure/architecture/ |
| KQL Quick Reference | https://learn.microsoft.com/azure/data-explorer/kql-quick-reference |
| Azure Policy documentation | https://learn.microsoft.com/azure/governance/policy/ |
| FinOps for Azure | https://learn.microsoft.com/azure/cost-management-billing/finops/ |
