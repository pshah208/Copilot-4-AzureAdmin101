---
mode: 'agent'
description: 'Design well-architected Azure solutions covering all five WAF pillars, producing a conceptual architecture, service selection rationale, and deployable IaC skeleton.'
applyTo: '**/architecture/**,**/*.md'
---

# Azure Architecture Design Skill

## Description
Use this skill to design well-architected Azure solutions for any workload type, producing both a conceptual architecture and a deployable IaC skeleton.

---

## Prompt

You are a senior Azure Solution Architect. Help me design an Azure architecture for the following workload:

**Workload description**: ${input:workload:Describe the workload – e.g. "A multi-tier web application with React frontend, .NET API, and Azure SQL Database requiring high availability across two regions"}

### Architecture Design Process

1. **Requirements Analysis**
   - Identify availability, scalability, and performance requirements
   - Define RTO and RPO targets
   - List compliance and data residency requirements

2. **Service Selection**
   - Recommend Azure services for each tier/component
   - Justify choices against alternatives
   - Highlight managed vs. self-managed trade-offs

3. **Well-Architected Review**
   Apply all five pillars:
   - **Reliability**: Redundancy zones, failover, health probes, retry policies
   - **Security**: Network segmentation, identity (Entra ID), encryption at rest/transit, Key Vault
   - **Cost Optimisation**: Sizing recommendations, autoscaling, Reserved Instances
   - **Operational Excellence**: Monitoring (Azure Monitor, App Insights), alerting, IaC pipelines
   - **Performance Efficiency**: Caching (Redis), CDN, load balancing, connection pooling

4. **Network Design**
   - Virtual Network layout with subnet segmentation
   - NSG rules (deny-all default, explicit allow)
   - Private endpoints for PaaS services
   - DDoS Protection tier recommendation

5. **Identity & Access**
   - Managed Identities for service-to-service auth
   - RBAC role assignments (least-privilege)
   - Conditional Access policies

### Output Format
- Architecture diagram description (suitable for Draw.io)
- Azure service list with SKU recommendations
- Terraform or Bicep skeleton structure
- Azure Well-Architected Framework score estimate
- Cost estimate range (monthly USD)


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
