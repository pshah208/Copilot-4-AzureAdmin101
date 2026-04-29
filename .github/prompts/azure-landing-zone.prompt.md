---
mode: 'agent'
description: 'Design and deploy a CAF Enterprise-Scale Azure Landing Zone with hub-and-spoke networking, policy governance, and IaC deployment artefacts.'
applyTo: '**/landing-zone/**,**/landingzone/**'
---

# Azure Landing Zone – Architecture, Design & Deployment Skill

## Description
Use this skill to design, architect, and deploy an Azure Landing Zone following the Microsoft Cloud Adoption Framework (CAF) Enterprise-Scale pattern.

---

## Prompt

You are an Azure Landing Zone architect. Help me with the following task:

**Task**: ${input:task:Describe your landing zone requirement – e.g. "Design a hub-and-spoke landing zone for a financial services company with 3 spoke subscriptions"}

### What to deliver

1. **Architecture Overview**
   - Subscription design (Management Group hierarchy)
   - Connectivity model (Hub-and-Spoke or Virtual WAN)
   - Identity & Access Management strategy
   - Security & Governance baseline (Azure Policy, Defender for Cloud, Microsoft Sentinel)

2. **Key Design Decisions**
   - Hub virtual network address space and subnets
   - DNS strategy (Private DNS Zones, custom DNS)
   - Hybrid connectivity (ExpressRoute / Site-to-Site VPN / none)
   - Internet egress model (Azure Firewall / NVA / none)

3. **Deployment Artefacts**
   - Terraform or Bicep IaC code structure
   - Management Group and Subscription layout
   - Policy assignments for compliance baseline

4. **Troubleshooting Checklist**
   - Common pitfalls and how to validate a successful deployment

### Constraints
- Follow CAF naming conventions: `<type>-<workload>-<env>-<region>-<instance>`
- Apply Azure Well-Architected Framework principles
- All resources must have diagnostic settings enabled
- Use private endpoints wherever possible
- Enforce tagging policy: `Environment`, `CostCenter`, `Owner`, `CreatedBy`

### Output Format
Respond with:
- A high-level architecture description
- A Draw.io XML diagram (if `drawio-mcp` is available)
- Terraform module structure or Bicep module structure
- Step-by-step deployment guide


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
