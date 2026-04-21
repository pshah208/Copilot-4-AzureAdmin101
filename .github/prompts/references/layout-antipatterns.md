# Draw.io Layout Anti-Patterns

Common layout problems and how to fix them in Azure architecture diagrams.

---

## Anti-Pattern 1: Spaghetti Edges

**Problem**: Many edges crossing each other, making the diagram unreadable.

**Example (bad)**:
- 8 services all connected to each other with direct edges
- Edges overlap and cross multiple times
- No clear flow direction

**Fix**:
- Enforce a consistent left-to-right or top-to-bottom flow direction
- Use waypoints (`<Array as="points">`) to route edges around containers
- Group related services inside containers so internal connections stay local
- Use `edgeStyle=orthogonalEdgeStyle` to keep edges at right angles

---

## Anti-Pattern 2: Icon Per Step (Over-Iconification)

**Problem**: Every small processing step gets its own Azure icon, producing a wall of 20+ icons.

**Example (bad)**:
- App Service → Function (receive) → Function (validate) → Function (transform) → Cosmos DB → Function (notify) → Service Bus

**Fix**:
- Use one icon per **major service** (App Service, Cosmos DB, Service Bus)
- Combine minor processing steps into a single labelled shape or swimlane
- Use stage numbers (1, 2, 3) on edges instead of a separate icon per step
- Rule of thumb: if two shapes have the same icon type, consider merging them

---

## Anti-Pattern 3: Missing Container Hierarchy

**Problem**: Resources are scattered across the canvas with no visual grouping, making it impossible to see which resources share a VNet/subnet/resource group.

**Example (bad)**:
- VM, SQL, AKS, Key Vault placed as individual shapes with no enclosing containers
- Network topology is invisible

**Fix**:
- Wrap resources in containers: Resource Group → VNet → Subnet → Resource
- Use the VNet/Subnet styles from the Professional Network Topology Patterns section:
  - VNet: `fillColor=#d5e8d4;strokeColor=#82b366;strokeWidth=4;container=1`
  - Subnet: `fillColor=#e6f4ea;strokeColor=#82b366;strokeWidth=2;dashed=1;dashPattern=8 8;container=1`
- Set `parent="subnetId"` on resources so they render inside their subnet

---

## Anti-Pattern 4: Self-Closing Edge Cells

**Problem**: Edge `mxCell` elements are self-closing (no `mxGeometry` child), causing parse errors or invisible edges.

**Example (bad)**:
```xml
<mxCell id="e1" edge="1" source="a" target="b" parent="1"/>
```

**Fix** — always include an `mxGeometry` child:
```xml
<mxCell id="e1" edge="1" source="a" target="b" parent="1">
  <mxGeometry relative="1" as="geometry"/>
</mxCell>
```

---

## Anti-Pattern 5: Double-Hyphen XML Comments

**Problem**: XML comments containing `--` are illegal per the XML specification and cause parse failures.

**Example (bad)**:
```xml
<!-- Hub -- Spoke topology -- v2 -->
```

**Fix** — use single hyphens or rephrase:
```xml
<!-- Hub-Spoke topology v2 -->
```

---

## Anti-Pattern 6: Unverified Azure Icon Paths

**Problem**: Using `shape=mxgraph.azure2.*` or guessing icon paths like `img/lib/azure2/compute/Virtual_Machines.svg` (wrong plural).

**Example (bad)**:
```xml
style="shape=mxgraph.azure2.virtual_machine;"
style="image=img/lib/azure2/compute/Virtual_Machines.svg;"  <!-- wrong -->
```

**Fix**:
- Always grep `references/azure2-complete-catalog.txt` before using any `img/lib/azure2/...` path
- Use the `image;aspect=fixed;html=1;...` style format
- Correct example: `image=img/lib/azure2/compute/Virtual_Machine.svg` (singular)

---

## Anti-Pattern 7: Canvas Too Small for Complex Topologies

**Problem**: Default canvas size (1169x827) causes nodes to overlap in multi-VNet diagrams.

**Fix**:
- For complex multi-VNet/multi-region diagrams, set `pageWidth="1900" pageHeight="1500"` on `mxGraphModel`
- Space nodes at least 200px horizontally and 120px vertically
- Align everything to a 10px grid

---

## Anti-Pattern 8: Too Many Cross-Zone Dashed Lines

**Problem**: Every service has a monitoring line, an identity line, a DNS line, and a backup line — resulting in 40+ dashed edges overlapping.

**Fix**:
- Limit cross-lane dashed lines to:
  - One security/auth line (e.g., Key Vault → App)
  - One optional telemetry line (e.g., App → Log Analytics)
- Group monitoring/identity connections into a "Management Plane" swimlane rather than drawing individual edges
- Use a legend box to describe implicit connections instead of drawing each one

---

## Anti-Pattern 9: No Traffic Legend

**Problem**: Colored arrows have no explanation, making the diagram ambiguous.

**Fix**:
- Always include a Traffic Legend box (bottom-left corner)
- Each entry: colored arrow sample + protocol/port label
- Style: `fillColor=#ffffff;strokeColor=#000000;strokeWidth=3;`
- Example entries:
  - Red thick arrow → HTTPS:443 (internet ingress)
  - Blue dashed arrow → PostgreSQL:5432
  - Orange dashed arrow → RBAC/Identity

---

## Anti-Pattern 10: Flat Management Group Trees

**Problem**: Management group hierarchy drawn as a flat list of boxes instead of a tree, making parent-child relationships unclear.

**Fix**:
- Use top-to-bottom layout for hierarchy diagrams
- Parent groups should be visually larger containers enclosing child groups
- Or use a vertical swimlane structure with `swimlane;startSize=30;` cells
- Label each level: Tenant Root → Platform → Landing Zones → Workloads
