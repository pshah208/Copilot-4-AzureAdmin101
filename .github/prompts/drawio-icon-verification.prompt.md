---
mode: 'agent'
description: 'Strict Azure2 icon path verification workflow for Draw.io diagrams. Every image path must be confirmed against the azure2-complete-catalog.txt before use. Includes fallback rules and verified vs unverified path examples.'
applyTo: '**/*.drawio,**/*.drawio.xml,**/references/azure2-*'
---

# Draw.io Icon Verification Skill

## Description

Use this skill to verify every `image=img/lib/azure2/...` path in a Draw.io diagram against the official Azure2 catalog before the diagram is generated or output. This skill is a hard gate: **no unverified icon path may appear in generated diagram XML**.

---

## Verification Workflow

### Step 1: Extract All Icon Paths

Before generating any diagram XML, list every Azure service icon you intend to use. Example:

```
Planned icons:
- img/lib/azure2/networking/Application_Gateways.svg
- img/lib/azure2/compute/Virtual_Machine.svg
- img/lib/azure2/security/Key_Vaults.svg
```

### Step 2: Grep the Catalog

Search `.github/prompts/references/azure2-complete-catalog.txt` for each planned icon:

```bash
grep -i "application_gateway" .github/prompts/references/azure2-complete-catalog.txt
grep -i "virtual_machine"     .github/prompts/references/azure2-complete-catalog.txt
grep -i "key_vault"           .github/prompts/references/azure2-complete-catalog.txt
```

Use case-insensitive search (`-i`) and partial name matching. Also search by category:

```bash
grep -i "networking/"  .github/prompts/references/azure2-complete-catalog.txt
grep -i "^compute/"    .github/prompts/references/azure2-complete-catalog.txt
```

### Step 3: Verdict Per Icon

For each icon, record one of:

| Status | Meaning | Action |
|---|---|---|
| ✅ **Verified** | Exact path found in catalog | Use as-is |
| ⚠️ **Approximate** | Similar path found; exact name differs | Use catalog path, not planned path |
| ❌ **Not found** | No match in catalog | Apply fallback rules below |

### Step 4: Apply Fallback Rules

If an icon path **cannot be confirmed** in the catalog:

1. **Find the closest category icon**: grep the category folder (e.g., `networking/`) and choose the most semantically related icon available.
2. **Add a descriptive label**: compensate for the generic icon with a clear text label (e.g., "ExpressRoute Circuit").
3. **Never invent a path**: do not guess or construct a path that was not returned by grep. Invented paths cause broken images.
4. **Document the substitution**: in your response, list `[SUBSTITUTED] original-intent → actual-icon-used`.

### Step 5: Output Verification Report

Before emitting diagram XML, output a verification table:

```
Icon Verification Report
========================
✅ img/lib/azure2/networking/Application_Gateways.svg      — verified
✅ img/lib/azure2/compute/Virtual_Machine.svg              — verified
⚠️ img/lib/azure2/networking/ExpressRoute_Circuits.svg     — substituted with img/lib/azure2/networking/ExpressRoute.svg
❌ img/lib/azure2/networking/Invented_Service.svg          — NOT FOUND; removed from diagram
```

Only proceed to diagram generation after all icons are verified or substituted.

---

## Verified vs Unverified Path Examples

### ✅ Verified Paths (from catalog)

```
img/lib/azure2/networking/Front_Doors.svg
img/lib/azure2/networking/Application_Gateways.svg
img/lib/azure2/networking/Firewalls.svg
img/lib/azure2/networking/Virtual_Networks.svg
img/lib/azure2/networking/Load_Balancers.svg
img/lib/azure2/networking/Private_Endpoint.svg
img/lib/azure2/networking/VPN_Gateways.svg
img/lib/azure2/networking/Bastion.svg
img/lib/azure2/compute/Virtual_Machine.svg
img/lib/azure2/compute/Kubernetes_Services.svg
img/lib/azure2/compute/Function_Apps.svg
img/lib/azure2/databases/Azure_Cosmos_DB.svg
img/lib/azure2/databases/Azure_SQL.svg
img/lib/azure2/security/Key_Vaults.svg
img/lib/azure2/security/Azure_Sentinel.svg
img/lib/azure2/security/Azure_Defender.svg
img/lib/azure2/management_governance/Policy.svg
img/lib/azure2/management_governance/Monitor.svg
img/lib/azure2/analytics/Log_Analytics_Workspaces.svg
img/lib/azure2/storage/Storage_Accounts.svg
img/lib/azure2/identity/Managed_Identities.svg
img/lib/azure2/identity/Azure_Active_Directory.svg
```

### ❌ Unverified / Invented Paths (do NOT use)

```
img/lib/azure2/networking/ExpressRoute_Gateway.svg     ← wrong; use VPN_Gateways.svg or ExpressRoute.svg
img/lib/azure2/compute/AKS_Cluster.svg                 ← wrong; use Kubernetes_Services.svg
img/lib/azure2/security/Defender_For_Cloud.svg         ← wrong; use Azure_Defender.svg
img/lib/azure2/monitoring/Workbooks.svg                ← category wrong; use management_governance/Monitor.svg
shape=mxgraph.azure2.networking.firewall               ← WRONG style type; never use shape= for Azure2 icons
```

---

## MCP Validation (Optional)

If the `drawio-http` MCP server is available, validate the generated XML by calling `drawio/create_diagram` with a minimal test payload containing only the icons under verification. A successful render confirms path resolution.

```
Prefer local catalog grep as the primary verification method.
Use drawio-http MCP only as a secondary render confirmation.
```

---

## Hard Rules

1. **Never emit an unverified icon path in diagram XML.**
2. **Never use `shape=mxgraph.azure2.*` style** — use `image=img/lib/azure2/...` only.
3. **Never fabricate catalog paths** — all paths must come from grep output.
4. **Always output the verification report** before the diagram XML.
5. **Document every substitution** in the response.
