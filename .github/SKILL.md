---
name: drawio
description: "Generate Azure architecture diagrams as .drawio files using raw XML or the Draw.io MCP (`drawio/create_diagram`). Azure2 icon catalog with 648 verified icons, professional network topology patterns, CLI export to PNG/SVG/PDF. Use when the user asks to create architecture diagrams, flowcharts, sequence diagrams, network topology diagrams, or any visual diagram — especially Azure."
argument-hint: "Describe the diagram to create, Azure services to include, and optional export format (png, svg, pdf)"
---

# Draw.io Diagram Skill — Azure Specialized

Generate draw.io diagrams as native `.drawio` files using raw mxGraphModel XML or via the Draw.io MCP server (`drawio/create_diagram`). Includes a verified Azure2 icon catalog (648 icons), professional network topology patterns, and CLI export to PNG/SVG/PDF.

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

The MCP server is configured in `.vscode/mcp.json`:
```json
{
  "drawio-http": {
    "type": "http",
    "url": "https://mcp.draw.io/mcp"
  }
}
```

## Recommended Workflow (Azure Diagrams)

1. Grep `references/azure2-complete-catalog.txt` to verify all icon paths — no scripts needed at runtime.
2. **Hard gate**: If an icon path cannot be confirmed in the catalog, do **not** use it. Find an alternative via grep first.
3. **For Azure infrastructure/network diagrams**: apply Professional Network Topology Patterns (see section below).
4. Build a valid `mxGraphModel` payload using verified icons.
5. Create the diagram (MCP or raw XML).
6. Keep labels concise and explicit (service name + role).
7. Prefer one icon per major service and use edges for flow semantics (ingress/egress/peering/telemetry).

For non-Azure diagrams, skip icon lookup and create the diagram directly.

## Visual Quality Guardrails

Apply these defaults unless the user explicitly asks for a dense/technical view:

- Use 3–4 major lanes/zones max (e.g., Source, Pipeline, Azure target)
- Keep primary flow left-to-right with a single main path
- Use stage numbering (`1`, `2`, `3`, `4`) instead of many edge labels
- Keep one icon per major service; avoid icon-per-step layouts
- Limit cross-lane dashed lines to one security/auth line and one optional telemetry line
- Keep text concise (single purpose per box) and avoid multiline overload
- Prefer a "clean" variant first; add detail only if requested

For worked examples of common layout problems, see [references/layout-antipatterns.md](references/layout-antipatterns.md).

## Choosing the Output Format

Check the user's request for a format preference:

- `create a flowchart` → `flowchart.drawio`
- `png flowchart for login` → `login-flow.drawio.png`
- `svg: ER diagram` → `er-diagram.drawio.svg`
- `pdf architecture overview` → `architecture-overview.drawio.pdf`

If no format is mentioned, write the `.drawio` file.

### Supported Export Formats

| Format | Embed XML | Notes |
|--------|-----------|-------|
| `png` | Yes (`-e`) | Viewable everywhere, editable in draw.io |
| `svg` | Yes (`-e`) | Scalable, editable in draw.io |
| `pdf` | Yes (`-e`) | Printable, editable in draw.io |
| `jpg` | No | Lossy, no embedded XML support |

PNG, SVG, and PDF all support `--embed-diagram` — the exported file contains the full diagram XML, so opening it in draw.io recovers the editable diagram.

## Azure2 Icon Reference (648 Icons)

The file `references/azure2-complete-catalog.txt` contains all 648 Azure2 icon paths from the official `jgraph/drawio` repository. Use it as the canonical source — **no HTTP requests or scripts needed at runtime**.

### How to Discover Icons

```bash
grep -i "gateway" references/azure2-complete-catalog.txt
grep -i "virtual_machine\|load_balancer\|key_vault" references/azure2-complete-catalog.txt
```

### Icon Style Format

Use the Azure2 image style (SVG-based):
```text
image;aspect=fixed;html=1;points=[];align=center;image=img/lib/azure2/<category>/<Icon_Name>.svg;
```

For renderer resilience, absolute URLs also work:
```text
image;aspect=fixed;html=1;points=[];align=center;image=https://raw.githubusercontent.com/jgraph/drawio/dev/src/main/webapp/img/lib/azure2/<category>/<Icon_Name>.svg;
```

### Known-Good Azure2 Icon Examples

```text
image=img/lib/azure2/networking/Front_Doors.svg
image=img/lib/azure2/networking/Private_Link_Hub.svg
image=img/lib/azure2/networking/Network_Watcher.svg
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
image=img/lib/azure2/databases/Azure_Database_PostgreSQL_Server.svg
image=img/lib/azure2/identity/Managed_Identities.svg
image=img/lib/azure2/identity/Azure_Active_Directory.svg
image=img/lib/azure2/identity/Entra_Privileged_Identity_Management.svg
image=img/lib/azure2/identity/Conditional_Access.svg
image=img/lib/azure2/security/Key_Vaults.svg
image=img/lib/azure2/security/Azure_Sentinel.svg
image=img/lib/azure2/security/Azure_Defender.svg
image=img/lib/azure2/management_governance/Policy.svg
image=img/lib/azure2/management_governance/Monitor.svg
image=img/lib/azure2/analytics/Log_Analytics_Workspaces.svg
image=img/lib/azure2/devops/Application_Insights.svg
image=img/lib/azure2/storage/Storage_Accounts.svg
image=img/lib/azure2/ai_machine_learning/Azure_OpenAI.svg
```

### Azure Icon Caveats

1. **Wrong style type** — `shape=mxgraph.azure2.*` may not render in some hosts. Prefer the image style: `image;aspect=fixed;html=1;...;image=img/lib/azure2/<category>/<Icon_Name>.svg;`
2. **Library/environment mismatch** — Some embedded viewers/extensions do not resolve `img/lib/azure2/...` consistently. If icons do not render in one host, test in `app.diagrams.net`.

### Fallback Strategy if Icons Fail

- Do **not** generate the diagram with unresolved icons
- Return the missing icon list and propose verified replacements (grepped from the catalog)
- After replacements validate to `OK`, generate the diagram

## Professional Network Topology Patterns (Azure Infrastructure)

When creating Azure infrastructure/network diagrams with VNets, subnets, and network isolation:

### Canvas Sizing
- Use larger canvas for complex infrastructure: `pageWidth="1900" pageHeight="1500"`
- Standard canvas may be too small for multi-VNet topologies

### VNet and Subnet Visualization
- **VNets**: Use thick borders (`strokeWidth=4`) and large containers
  - DMZ VNet: Yellow (`fillColor=#fff2cc`, `strokeColor=#d6b656`)
  - Internal VNet: Green (`fillColor=#d5e8d4`, `strokeColor=#82b366`)
  - Management Zone: Blue (`fillColor=#dae8fc`, `strokeColor=#6c8ebf`)
- **Subnets**: Use dashed borders (`strokeWidth=2`, `dashed=1`, `dashPattern=8 8`)
  - Position subnet containers **inside** VNet containers
  - Use lighter shades of parent VNet color
  - Label with subnet name and CIDR (e.g., "Application Subnet - 10.x.2.0/24")
- **Delegated Subnets**: Add delegation info to label (e.g., "PostgreSQL Subnet - 10.x.4.0/24 (Delegated to Microsoft.DBforPostgreSQL/flexibleServers)")

### Resource Positioning
- Position all resources **inside their respective subnet containers**
- VMs, databases, load balancers must be visually contained within their subnets
- This clearly shows network isolation boundaries

### Traffic Flow Visualization
- **Label all traffic arrows** with protocols and ports:
  - HTTPS:443 (red thick arrows for internet ingress)
  - HTTP:8080/8090/8095 (gold arrows for backend pools)
  - PostgreSQL:5432 (blue dashed arrows for database connections)
  - NFS/Gluster (green arrows for shared storage)
  - RBAC/Identity/SMTP (orange dashed arrows for management/external)
- Use `edgeStyle=orthogonalEdgeStyle` for clean routing
- Include `<Array>` waypoints for complex routing

### Essential Components

1. **Traffic Legend Box** (bottom-left) — Show all traffic types with color-coded arrows, include protocol/port information, use thick bordered white box (`strokeWidth=3`)
2. **Network Isolation Explanation Box** (top-left) — Explain visual conventions: "VNets: Thick borders", "Subnets: Dashed borders", "NSGs control traffic", "Private DNS for internal resolution". Use yellow background (`fillColor=#fff9cc`)
3. **Zone Separation**:
   - VNet Peering Zone: Grey box (`fillColor=#f5f5f5`, `strokeColor=#666666`)
   - External Services Zone: Orange box (`fillColor=#ffe6cc`, `strokeColor=#d79b00`)

### Network Topology Example

```xml
<mxGraphModel pageWidth="1900" pageHeight="1500">
  <root>
    <mxCell id="0"/>
    <mxCell id="1" parent="0"/>
    <!-- VNet Container with thick border -->
    <mxCell id="vnet" value="Internal VNet - 10.x.0.0/16"
      style="rounded=0;whiteSpace=wrap;html=1;fillColor=#d5e8d4;strokeColor=#82b366;verticalAlign=top;fontSize=16;fontStyle=1;align=center;strokeWidth=4;container=1;pointerEvents=0;"
      vertex="1" parent="1">
      <mxGeometry x="220" y="580" width="1340" height="820" as="geometry"/>
    </mxCell>
    <!-- Subnet Container with dashed border inside VNet -->
    <mxCell id="subnet-app" value="Application Subnet - 10.x.2.0/24"
      style="rounded=1;whiteSpace=wrap;html=1;fillColor=#e6f4ea;strokeColor=#82b366;verticalAlign=top;fontSize=13;fontStyle=1;align=center;strokeWidth=2;dashed=1;dashPattern=8 8;container=1;pointerEvents=0;"
      vertex="1" parent="vnet">
      <mxGeometry x="40" y="70" width="480" height="340" as="geometry"/>
    </mxCell>
    <!-- Azure resource inside subnet -->
    <mxCell id="vm" value="App VM"
      style="image;aspect=fixed;html=1;points=[];align=center;image=img/lib/azure2/compute/Virtual_Machine.svg;"
      vertex="1" parent="subnet-app">
      <mxGeometry x="80" y="80" width="64" height="59" as="geometry"/>
    </mxCell>
    <!-- Labeled traffic edge -->
    <mxCell id="edge-db" value="PostgreSQL:5432"
      style="edgeStyle=orthogonalEdgeStyle;strokeWidth=2;strokeColor=#6c8ebf;dashed=1;"
      edge="1" source="vm" target="postgres" parent="1">
      <mxGeometry relative="1" as="geometry"/>
    </mxCell>
  </root>
</mxGraphModel>
```

### Professional Topology Checklist
- [ ] VNets have thick borders (strokeWidth=4)
- [ ] Subnets have dashed borders (strokeWidth=2, dashPattern=8 8)
- [ ] All resources positioned inside their subnets
- [ ] Traffic arrows labeled with protocols and ports
- [ ] Traffic legend box included
- [ ] Network isolation explanation box included
- [ ] Color-coded zones for different purposes
- [ ] Canvas sized appropriately (1900x1500 for complex infra)
- [ ] VNet peering connections shown in separate zone
- [ ] External services grouped in separate zone

## draw.io CLI

The draw.io desktop app includes a command-line interface for exporting.

### Locating the CLI

Try `drawio` first (works if on PATH), then fall back to the platform-specific path:

- **Windows**: `"C:\Program Files\draw.io\draw.io.exe"`
- **macOS**: `/Applications/draw.io.app/Contents/MacOS/draw.io`
- **Linux**: `drawio` (typically on PATH via snap/apt/flatpak)

Use `where drawio` (Windows) or `which drawio` (macOS/Linux) to check if it's on PATH before falling back.

### Export Command

```bash
drawio -x -f <format> -e -b 10 -o <output> <input.drawio>
```

Key flags:
- `-x` / `--export`: export mode
- `-f` / `--format`: output format (png, svg, pdf, jpg)
- `-e` / `--embed-diagram`: embed diagram XML in the output (PNG, SVG, PDF only)
- `-o` / `--output`: output file path
- `-b` / `--border`: border width around diagram (default: 0)
- `-t` / `--transparent`: transparent background (PNG only)
- `-s` / `--scale`: scale the diagram size
- `--width` / `--height`: fit into specified dimensions (preserves aspect ratio)
- `-a` / `--all-pages`: export all pages (PDF only)
- `-p` / `--page-index`: select a specific page (1-based)

### Opening the Result

- **Windows**: `start <file>`
- **macOS**: `open <file>`
- **Linux**: `xdg-open <file>`

## File Naming

- Use a descriptive filename based on the diagram content (e.g., `hub-spoke-topology`, `payment-api-threat-model`)
- Use lowercase with hyphens for multi-word names
- For export, use double extensions: `name.drawio.png`, `name.drawio.svg`, `name.drawio.pdf` — this signals the file contains embedded diagram XML
- After a successful export, delete the intermediate `.drawio` file — the exported file contains the full diagram

## XML Format

A `.drawio` file is native mxGraphModel XML. Always generate XML directly — Mermaid and CSV formats require server-side conversion and cannot be saved as native files.

### Basic Structure

Every diagram must have this structure:

```xml
<mxGraphModel>
  <root>
    <mxCell id="0"/>
    <mxCell id="1" parent="0"/>
    <!-- Diagram cells go here with parent="1" -->
  </root>
</mxGraphModel>
```

- Cell `id="0"` is the root layer
- Cell `id="1"` is the default parent layer
- All diagram elements use `parent="1"` unless using multiple layers

### Common Styles

**Rounded rectangle:**
```xml
<mxCell id="2" value="Label" style="rounded=1;whiteSpace=wrap;" vertex="1" parent="1">
  <mxGeometry x="100" y="100" width="120" height="60" as="geometry"/>
</mxCell>
```

**Diamond (decision):**
```xml
<mxCell id="3" value="Condition?" style="rhombus;whiteSpace=wrap;" vertex="1" parent="1">
  <mxGeometry x="100" y="200" width="120" height="80" as="geometry"/>
</mxCell>
```

**Arrow (edge):**
```xml
<mxCell id="4" value="" style="edgeStyle=orthogonalEdgeStyle;" edge="1" source="2" target="3" parent="1">
  <mxGeometry relative="1" as="geometry"/>
</mxCell>
```

**Labeled arrow:**
```xml
<mxCell id="5" value="Yes" style="edgeStyle=orthogonalEdgeStyle;" edge="1" source="3" target="6" parent="1">
  <mxGeometry relative="1" as="geometry"/>
</mxCell>
```

**Azure service icon:**
```xml
<mxCell id="6" value="App Gateway"
  style="image;aspect=fixed;html=1;points=[];align=center;image=img/lib/azure2/networking/Application_Gateways.svg;"
  vertex="1" parent="1">
  <mxGeometry x="200" y="100" width="64" height="64" as="geometry"/>
</mxCell>
```

### Useful Style Properties

| Property | Values | Use for |
|----------|--------|---------|
| `rounded=1` | 0 or 1 | Rounded corners |
| `whiteSpace=wrap` | wrap | Text wrapping |
| `fillColor=#dae8fc` | Hex color | Background color |
| `strokeColor=#6c8ebf` | Hex color | Border color |
| `fontColor=#333333` | Hex color | Text color |
| `strokeWidth=4` | integer | VNet thick borders |
| `dashed=1` | 0 or 1 | Dashed lines (subnets) |
| `dashPattern=8 8` | space-separated | Dash/gap lengths |
| `shape=cylinder3` | shape name | Database cylinders |
| `shape=mxgraph.flowchart.document` | shape name | Document shapes |
| `ellipse` | style keyword | Circles/ovals |
| `rhombus` | style keyword | Diamonds |
| `edgeStyle=orthogonalEdgeStyle` | style keyword | Right-angle connectors |
| `edgeStyle=elbowEdgeStyle` | style keyword | Elbow connectors |
| `swimlane` | style keyword | Swimlane containers |
| `group` | style keyword | Invisible container (pointerEvents=0) |
| `container=1` | 0 or 1 | Enable container behavior on any shape |
| `pointerEvents=0` | 0 or 1 | Prevent container from capturing child connections |

## Edge Routing

**CRITICAL: Every edge mxCell must contain a mxGeometry child element with relative="1"**, even when there are no waypoints. Self-closing edge cells are invalid and will not render correctly. Always use the expanded form:
```xml
<mxCell id="e1" edge="1" parent="1" source="a" target="b" style="...">
  <mxGeometry relative="1" as="geometry"/>
</mxCell>
```

draw.io does **not** have built-in collision detection for edges. Plan layout and routing carefully:

- Use `edgeStyle=orthogonalEdgeStyle` for right-angle connectors (most common)
- **Space nodes generously** — at least 60px apart, prefer 200px horizontal / 120px vertical gaps
- Use `exitX`/`exitY` and `entryX`/`entryY` (values 0-1) to control which side of a node an edge connects to. Spread connections across different sides to prevent overlap
- **Leave room for arrowheads**: Ensure at least 20px of straight segment before the target and after the source
- **Fan exit anchors** when 3+ edges leave the same node face — spread `exitX` values at least 0.15 apart and use waypoints:
  ```xml
  <mxCell id="e1" style="edgeStyle=orthogonalEdgeStyle;exitX=0.35;exitY=1;" edge="1" parent="1" source="a" target="b">
    <mxGeometry relative="1" x="-0.55" y="-16" as="geometry">
      <Array as="points">
        <mxPoint x="300" y="150"/>
        <mxPoint x="300" y="250"/>
      </Array>
    </mxGeometry>
  </mxCell>
  ```
- Use `rounded=1` on edges for cleaner bends
- Use `jettySize=auto` for better port spacing on orthogonal edges
- Align all nodes to a grid (multiples of 10)

## Containers and Groups

For architecture diagrams or any diagram with nested elements, use draw.io's proper parent-child containment.

### How Containment Works

Set `parent="containerId"` on child cells. Children use **relative coordinates** within the container.

### Container Types

| Type | Style | When to use |
|------|-------|-------------|
| **Group** (invisible) | `group;` | No visual border needed, container has no connections |
| **Swimlane** (titled) | `swimlane;startSize=30;` | Container needs a visible title bar/header |
| **Custom container** | Add `container=1;pointerEvents=0;` to any shape style | Any shape acting as a container |

### Key Rules

- **Always add `pointerEvents=0;`** to container styles that should not capture connections
- Only omit `pointerEvents=0` when the container itself needs to be connectable
- Children must set `parent="containerId"` and use coordinates **relative to the container**

### Example: Architecture Container with Swimlane

```xml
<mxCell id="svc1" value="User Service" style="swimlane;startSize=30;fillColor=#dae8fc;strokeColor=#6c8ebf;" vertex="1" parent="1">
  <mxGeometry x="100" y="100" width="300" height="200" as="geometry"/>
</mxCell>
<mxCell id="api1" value="REST API" style="rounded=1;whiteSpace=wrap;" vertex="1" parent="svc1">
  <mxGeometry x="20" y="40" width="120" height="60" as="geometry"/>
</mxCell>
<mxCell id="db1" value="Database" style="shape=cylinder3;whiteSpace=wrap;" vertex="1" parent="svc1">
  <mxGeometry x="160" y="40" width="120" height="60" as="geometry"/>
</mxCell>
```

## Troubleshooting Checklist

- Confirm MCP server appears in `MCP: List Servers`
- Run `MCP: Reset Cached Tools` if tool list is stale
- Ensure XML is well-formed (no malformed tags or invalid comments)
- Verify style uses `image=img/lib/azure2/...` for Azure2 icon mode (not `shape=mxgraph.azure2.*`)
- Reopen diagram in web draw.io (`app.diagrams.net`) if VS Code extension rendering differs
- If an icon path looks wrong, grep `references/azure2-complete-catalog.txt` for alternatives
- If the catalog itself appears stale, re-run the refresh workflow in `references/REFERENCE.md`

## CRITICAL: XML Well-Formedness

- **NEVER use double hyphens inside XML comments.** Double hyphens are illegal inside XML comment blocks per the XML spec and cause parse errors. Use single hyphens or rephrase.
- Escape special characters in attribute values: `&amp;`, `&lt;`, `&gt;`, `&quot;`
- Always use unique `id` values for each `mxCell`
- Always emit one `mxCell` per line with child elements indented — never minify to a single line

## Style Reference

For the complete draw.io style reference: https://www.drawio.com/doc/faq/drawio-style-reference.html

For the XML Schema Definition (XSD): https://www.drawio.com/assets/mxfile.xsd

## Definition of Done

- For non-Azure diagrams: diagram is generated and renders correctly
- For Azure diagrams: all icon paths confirmed against `references/azure2-complete-catalog.txt` before calling `drawio/create_diagram`
- If render issues found, alternative icon paths sourced from catalog and substituted
- Diagram generated via `drawio/create_diagram` (MCP) or raw XML only with confirmed icon paths
- XML is valid and opens in draw.io
- Azure resources are identifiable (icons and clear service labels)
- **For Azure infrastructure/network diagrams**:
  - VNets use thick borders (strokeWidth=4) and are color-coded
  - Subnets use dashed borders (strokeWidth=2, dashPattern=8 8)
  - All resources positioned inside their respective subnets
  - All traffic flows labeled with protocols and ports
  - Traffic legend box included (bottom-left)
  - Network isolation explanation box included (top-left)
  - Canvas appropriately sized (1900x1500 for complex topologies)
  - VNet peering and external services in separate zones
- Layout anti-patterns checked against [references/layout-antipatterns.md](references/layout-antipatterns.md) before finalizing
