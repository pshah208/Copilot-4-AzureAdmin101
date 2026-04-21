---
mode: 'agent'
description: 'Generate Azure architecture diagrams as .drawio files using the official Azure2 icon catalog (638 verified icons), professional network topology patterns, and CLI export to PNG/SVG/PDF.'
applyTo: '**/*.drawio,**/*.drawio.xml,**/diagrams/**'
---

# Draw.io Diagram Skill — Azure Specialized

Generate draw.io diagrams as native `.drawio` files using raw mxGraphModel XML or via the Draw.io MCP server (`drawio/create_diagram`). Includes a verified Azure2 icon catalog (638 icons), professional network topology patterns, and CLI export to PNG/SVG/PDF.

## Diagram Creation Modes

### Mode 1: Raw XML (offline, no MCP required)
1. Generate draw.io XML in mxGraphModel format
2. Write the XML to a `.drawio` file
3. Optionally export via the draw.io CLI

### Mode 2: Draw.io MCP (live, requires MCP server)
1. Verify Azure icon paths against `references/azure2-complete-catalog.txt`
2. Build a valid `mxGraphModel` XML payload with verified icons
3. Call `drawio/create_diagram` with the XML
4. If user wants a file artifact, save as `.drawio` wrapped in `<mxfile><diagram>...</diagram></mxfile>`

The MCP server is configured in `.vscode/mcp.json` as:

    "drawio-http": { "type": "http", "url": "https://mcp.draw.io/mcp" }

## Recommended Workflow (Azure Diagrams)

1. Grep `references/azure2-complete-catalog.txt` to verify all icon paths — no scripts needed at runtime.
2. **Hard gate**: If an icon path cannot be confirmed in the catalog, do **not** use it. Find an alternative via grep first.
3. For Azure infrastructure/network diagrams, apply Professional Network Topology Patterns (below).
4. Build a valid `mxGraphModel` payload using verified icons.
5. Create the diagram (MCP or raw XML).
6. Keep labels concise and explicit (service name + role).
7. Prefer one icon per major service and use edges for flow semantics (ingress/egress/peering/telemetry).

For non-Azure diagrams, skip icon lookup and create the diagram directly.

## Visual Quality Guardrails

Apply these defaults unless the user explicitly asks for a dense/technical view:
- Use 3-4 major lanes/zones max
- Keep primary flow left-to-right with a single main path
- Use stage numbering (1, 2, 3, 4) instead of many edge labels
- Keep one icon per major service; avoid icon-per-step layouts
- Limit cross-lane dashed lines to one security/auth line and one optional telemetry line
- Keep text concise; prefer a "clean" variant first

See `references/layout-antipatterns.md` for worked examples.

## Azure2 Icon Reference (638 Icons)

The file `references/azure2-complete-catalog.txt` contains all Azure2 icon paths from the official `jgraph/drawio` repository.

Discover icons with grep:

    grep -i "gateway" references/azure2-complete-catalog.txt
    grep -i "virtual_machine\|load_balancer\|key_vault" references/azure2-complete-catalog.txt

### Icon Style Format

Use the Azure2 image style (SVG-based):

    image;aspect=fixed;html=1;points=[];align=center;image=img/lib/azure2/<category>/<Icon_Name>.svg;

For renderer resilience, absolute URLs also work:

    image;aspect=fixed;html=1;points=[];align=center;image=https://raw.githubusercontent.com/jgraph/drawio/dev/src/main/webapp/img/lib/azure2/<category>/<Icon_Name>.svg;

### Known-Good Examples

    image=img/lib/azure2/networking/Front_Doors.svg
    image=img/lib/azure2/networking/Application_Gateways.svg
    image=img/lib/azure2/networking/Firewalls.svg
    image=img/lib/azure2/networking/Virtual_Networks.svg
    image=img/lib/azure2/networking/Load_Balancers.svg
    image=img/lib/azure2/networking/Private_Endpoint.svg
    image=img/lib/azure2/app_services/API_Management_Services.svg
    image=img/lib/azure2/app_services/App_Services.svg
    image=img/lib/azure2/compute/Virtual_Machine.svg
    image=img/lib/azure2/compute/Kubernetes_Services.svg
    image=img/lib/azure2/compute/Function_Apps.svg
    image=img/lib/azure2/databases/Azure_Cosmos_DB.svg
    image=img/lib/azure2/databases/Azure_SQL.svg
    image=img/lib/azure2/identity/Managed_Identities.svg
    image=img/lib/azure2/identity/Azure_Active_Directory.svg
    image=img/lib/azure2/security/Key_Vaults.svg
    image=img/lib/azure2/security/Azure_Sentinel.svg
    image=img/lib/azure2/security/Azure_Defender.svg
    image=img/lib/azure2/management_governance/Policy.svg
    image=img/lib/azure2/management_governance/Monitor.svg
    image=img/lib/azure2/analytics/Log_Analytics_Workspaces.svg
    image=img/lib/azure2/devops/Application_Insights.svg
    image=img/lib/azure2/storage/Storage_Accounts.svg
    image=img/lib/azure2/ai_machine_learning/Azure_OpenAI.svg

### Azure Icon Caveats

1. **Wrong style type** — `shape=mxgraph.azure2.*` may not render in some hosts. Prefer the image style shown above.
2. **Library/environment mismatch** — Some embedded viewers do not resolve `img/lib/azure2/...` consistently. Test in `app.diagrams.net` if rendering fails.

### Fallback Strategy if Icons Fail

- Do NOT generate the diagram with unresolved icons.
- Return the missing icon list and propose verified replacements grepped from the catalog.
- After replacements validate to OK, generate the diagram.

## Professional Network Topology Patterns (Azure Infrastructure)

Use when creating Azure infrastructure/network diagrams with VNets, subnets, and network isolation.

### Canvas Sizing
Use `pageWidth="1900" pageHeight="1500"` for complex multi-VNet topologies.

### VNets and Subnets
- **VNets**: thick borders (`strokeWidth=4`), large containers
  - DMZ VNet: `fillColor=#fff2cc`, `strokeColor=#d6b656` (yellow)
  - Internal VNet: `fillColor=#d5e8d4`, `strokeColor=#82b366` (green)
  - Management: `fillColor=#dae8fc`, `strokeColor=#6c8ebf` (blue)
- **Subnets**: dashed borders (`strokeWidth=2`, `dashed=1`, `dashPattern=8 8`)
  - Inside VNet containers
  - Lighter shade of parent VNet color
  - Label with name + CIDR, e.g. `"Application Subnet - 10.x.2.0/24"`
- **Delegated subnets**: add delegation in label, e.g. `"PostgreSQL Subnet - 10.x.4.0/24 (Delegated to Microsoft.DBforPostgreSQL/flexibleServers)"`

### Resource Positioning
All VMs, DBs, LBs must be positioned **inside** their subnet containers to show isolation boundaries.

### Traffic Flow Labels
- HTTPS:443 — red thick arrows for internet ingress
- HTTP:8080/8090/8095 — gold arrows for backend pools
- PostgreSQL:5432 — blue dashed arrows for DB connections
- NFS/Gluster — green for shared storage
- RBAC/Identity/SMTP — orange dashed for management/external

Use `edgeStyle=orthogonalEdgeStyle` and `<Array>` waypoints for complex routing.

### Essential Boxes
1. **Traffic Legend** (bottom-left): color-coded arrows + protocol/port; thick white box (`strokeWidth=3`).
2. **Network Isolation Explanation** (top-left): "VNets: thick borders / Subnets: dashed / NSGs control traffic / Private DNS for internal resolution"; yellow bg (`fillColor=#fff9cc`).
3. **Zones**:
   - VNet Peering Zone: grey (`fillColor=#f5f5f5`, `strokeColor=#666666`)
   - External Services Zone: orange (`fillColor=#ffe6cc`, `strokeColor=#d79b00`)

### Topology Example

    <mxGraphModel pageWidth="1900" pageHeight="1500">
      <root>
        <mxCell id="0"/>
        <mxCell id="1" parent="0"/>
        <mxCell id="vnet" value="Internal VNet - 10.x.0.0/16"
          style="rounded=0;whiteSpace=wrap;html=1;fillColor=#d5e8d4;strokeColor=#82b366;verticalAlign=top;fontSize=16;fontStyle=1;align=center;strokeWidth=4;container=1;pointerEvents=0;"
          vertex="1" parent="1">
          <mxGeometry x="220" y="580" width="1340" height="820" as="geometry"/>
        </mxCell>
        <mxCell id="subnet-app" value="Application Subnet - 10.x.2.0/24"
          style="rounded=1;whiteSpace=wrap;html=1;fillColor=#e6f4ea;strokeColor=#82b366;verticalAlign=top;fontSize=13;fontStyle=1;align=center;strokeWidth=2;dashed=1;dashPattern=8 8;container=1;pointerEvents=0;"
          vertex="1" parent="vnet">
          <mxGeometry x="40" y="70" width="480" height="340" as="geometry"/>
        </mxCell>
        <mxCell id="vm" value="App VM"
          style="image;aspect=fixed;html=1;points=[];align=center;image=img/lib/azure2/compute/Virtual_Machine.svg;"
          vertex="1" parent="subnet-app">
          <mxGeometry x="80" y="80" width="64" height="59" as="geometry"/>
        </mxCell>
      </root>
    </mxGraphModel>

### Topology Checklist
- VNets: thick borders (strokeWidth=4)
- Subnets: dashed borders (strokeWidth=2, dashPattern=8 8)
- Resources inside their subnets
- Traffic arrows labeled with protocols/ports
- Traffic legend box included (bottom-left)
- Network isolation explanation box (top-left)
- Color-coded zones
- Canvas 1900x1500 for complex infra
- VNet peering + external services in separate zones

## draw.io CLI

Locate:
- Windows: `"C:\Program Files\draw.io\draw.io.exe"`
- macOS: `/Applications/draw.io.app/Contents/MacOS/draw.io`
- Linux: `drawio` (snap/apt/flatpak)

Export:

    drawio -x -f <format> -e -b 10 -o <output> <input.drawio>

Flags: `-x` export, `-f` format (png/svg/pdf/jpg), `-e` embed XML, `-o` output, `-b` border, `-t` transparent, `-s` scale, `--width/--height`, `-a` all pages, `-p` page index.

PNG, SVG, PDF all support embedded XML — re-opening the exported file in draw.io recovers the editable diagram.

## File Naming

- Descriptive, lowercase, hyphenated (`hub-spoke-topology.drawio`).
- Exports use double extensions: `name.drawio.png`, `name.drawio.svg`, `name.drawio.pdf`.
- After successful export, delete the intermediate `.drawio` — the exported file contains the full XML.

## XML Format

Every diagram must use this structure:

    <mxGraphModel>
      <root>
        <mxCell id="0"/>
        <mxCell id="1" parent="0"/>
        <!-- cells go here with parent="1" -->
      </root>
    </mxGraphModel>

### Common Styles

Rounded rectangle:

    <mxCell id="2" value="Label" style="rounded=1;whiteSpace=wrap;" vertex="1" parent="1">
      <mxGeometry x="100" y="100" width="120" height="60" as="geometry"/>
    </mxCell>

Diamond:

    <mxCell id="3" value="Condition?" style="rhombus;whiteSpace=wrap;" vertex="1" parent="1">
      <mxGeometry x="100" y="200" width="120" height="80" as="geometry"/>
    </mxCell>

Edge (required `mxGeometry` child):

    <mxCell id="4" style="edgeStyle=orthogonalEdgeStyle;" edge="1" source="2" target="3" parent="1">
      <mxGeometry relative="1" as="geometry"/>
    </mxCell>

Azure service icon:

    <mxCell id="6" value="App Gateway"
      style="image;aspect=fixed;html=1;points=[];align=center;image=img/lib/azure2/networking/Application_Gateways.svg;"
      vertex="1" parent="1">
      <mxGeometry x="200" y="100" width="64" height="64" as="geometry"/>
    </mxCell>

## Edge Routing

**CRITICAL**: every edge `mxCell` must contain an `mxGeometry` child with `relative="1"`, even with no waypoints. Self-closing edge cells are invalid.

- Use `edgeStyle=orthogonalEdgeStyle` for right angles
- Space nodes generously (>=60px, prefer 200px horizontal / 120px vertical)
- Use `exitX/exitY` and `entryX/entryY` (0-1) to control connection sides
- Leave >=20px straight segment before/after arrowheads
- Fan exit anchors (>=0.15 apart) when 3+ edges leave the same face; add waypoints via `<Array as="points">`
- `rounded=1` on edges for cleaner bends; `jettySize=auto` for orthogonal spacing
- Align nodes to a grid (multiples of 10)

## Containers and Groups

Set `parent="containerId"` on children; children use coordinates **relative** to the container.

| Type | Style | When |
|---|---|---|
| Group (invisible) | `group;` | no visual border |
| Swimlane (titled) | `swimlane;startSize=30;` | visible title bar |
| Custom container | add `container=1;pointerEvents=0;` to any shape | any shape as container |

Add `pointerEvents=0;` unless the container itself must be connectable.

## CRITICAL: XML Well-Formedness

- **NEVER use double hyphens inside XML comments** — illegal per spec, causes parse errors. Use single hyphens or rephrase.
- Escape special chars in attributes: `&amp;`, `&lt;`, `&gt;`, `&quot;`.
- Unique `id` per `mxCell`.
- Emit one `mxCell` per line with indented children; never minify.

## Troubleshooting

- Confirm MCP server appears in `MCP: List Servers`
- Run `MCP: Reset Cached Tools` if tool list is stale
- Ensure XML is well-formed
- Verify Azure2 icon style uses `image=img/lib/azure2/...` (not `shape=mxgraph.azure2.*`)
- Reopen in `app.diagrams.net` if the VS Code extension rendering differs
- Grep `references/azure2-complete-catalog.txt` for alternatives if an icon path looks wrong

## Style Reference

- https://www.drawio.com/doc/faq/drawio-style-reference.html
- https://www.drawio.com/assets/mxfile.xsd

## Definition of Done

- Non-Azure: diagram generated, renders correctly
- Azure: all icon paths confirmed against `references/azure2-complete-catalog.txt` before calling `drawio/create_diagram`
- Alternative icons sourced from catalog if render fails
- Diagram generated via `drawio/create_diagram` (MCP) or raw XML only with confirmed icons
- XML valid, opens in draw.io
- Azure resources identifiable (icons + clear labels)
- For infra/network diagrams: topology checklist above satisfied
- Layout anti-patterns checked against `references/layout-antipatterns.md`
