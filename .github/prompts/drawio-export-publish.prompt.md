---
mode: 'agent'
description: 'Export Draw.io diagrams to PNG, SVG, or PDF via the draw.io CLI and publish exported images to docs, README, or wiki. Covers CLI installation, batch export, embedding, and recommended directory layout.'
applyTo: '**/*.drawio,**/diagrams/**,**/exports/**'
---

# Draw.io Export & Publish Skill

## Description

Use this skill to export Draw.io diagrams to PNG, SVG, or PDF using the draw.io CLI, then embed the exported images in project documentation (README, wiki, or docs site). Covers CLI installation, single and batch export, embedding syntax, and recommended directory layout.

---

## Prompt

You are a documentation engineer. Help me export and publish the following Draw.io diagram(s):

**Diagram file(s)**: ${input:files:Path(s) to .drawio files – e.g. "diagrams/hub-spoke-topology.drawio"}
**Export format**: ${input:format:png / svg / pdf}
**Target docs location**: ${input:target:README.md section, wiki page, or docs/ folder}

---

## draw.io CLI

### Installation

| Platform | Method | Command |
|---|---|---|
| Linux (Snap) | Snap Store | `sudo snap install drawio` |
| Linux (Apt) | `.deb` package | Download from https://github.com/jgraph/drawio-desktop/releases |
| macOS | Homebrew | `brew install --cask drawio` |
| Windows | Installer | Download from https://github.com/jgraph/drawio-desktop/releases |
| CI / Docker | Headless Electron | `xvfb-run drawio …` (Linux CI) |

Verify installation:

```bash
drawio --version
```

### Single File Export

```bash
# Export to PNG (300 DPI, 10px border, embed XML for round-trip editing)
drawio -x -f png -e -b 10 -o diagrams/exports/hub-spoke-topology.drawio.png \
       diagrams/hub-spoke-topology.drawio

# Export to SVG (scalable, embed XML)
drawio -x -f svg -e -b 10 -o diagrams/exports/hub-spoke-topology.drawio.svg \
       diagrams/hub-spoke-topology.drawio

# Export to PDF (A3 landscape, all pages)
drawio -x -f pdf -a -b 10 -o diagrams/exports/hub-spoke-topology.drawio.pdf \
       diagrams/hub-spoke-topology.drawio
```

#### Key CLI Flags

| Flag | Description |
|---|---|
| `-x` | Export mode (required) |
| `-f <format>` | Output format: `png`, `svg`, `pdf`, `jpg` |
| `-e` | Embed diagram XML in export (enables round-trip editing) |
| `-b <px>` | Border padding in pixels |
| `-o <path>` | Output file path |
| `-a` | Export all pages (multi-page diagrams) |
| `-p <index>` | Export specific page index (0-based) |
| `-s <scale>` | Scale factor (default 1; use 2 for 2× resolution) |
| `--width <px>` | Force output width in pixels |
| `--height <px>` | Force output height in pixels |
| `-t` | Transparent background (PNG only) |
| `--crop` | Crop to diagram content bounds |

### Batch Export

Export all `.drawio` files in a directory to PNG:

```bash
#!/bin/bash
DIAGRAMS_DIR="diagrams"
EXPORTS_DIR="diagrams/exports"
mkdir -p "$EXPORTS_DIR"

for f in "$DIAGRAMS_DIR"/*.drawio; do
  base=$(basename "$f" .drawio)
  echo "Exporting $base..."
  drawio -x -f png -e -b 10 \
    -o "$EXPORTS_DIR/${base}.drawio.png" \
    "$f"
done
echo "Batch export complete."
```

Export all diagrams to both PNG and SVG:

```bash
for f in diagrams/*.drawio; do
  base=$(basename "$f" .drawio)
  drawio -x -f png -e -b 10 -o "diagrams/exports/${base}.drawio.png" "$f"
  drawio -x -f svg -e -b 10 -o "diagrams/exports/${base}.drawio.svg" "$f"
done
```

### CI/CD Export (GitHub Actions)

```yaml
name: Export Draw.io Diagrams

on:
  push:
    paths: ['diagrams/**/*.drawio']

jobs:
  export-diagrams:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install draw.io CLI
        run: |
          wget -q https://github.com/jgraph/drawio-desktop/releases/download/v24.7.17/drawio-amd64-24.7.17.deb
          sudo apt-get install -y ./drawio-amd64-24.7.17.deb

      - name: Export all diagrams to PNG
        run: |
          mkdir -p diagrams/exports
          for f in diagrams/*.drawio; do
            base=$(basename "$f" .drawio)
            xvfb-run drawio -x -f png -e -b 10 \
              -o "diagrams/exports/${base}.drawio.png" "$f"
          done

      - name: Commit exported images
        run: |
          git config user.name  "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add diagrams/exports/
          git diff --cached --quiet || git commit -m "chore: update exported diagram images"
          git push
```

---

## Embedding Exported Images in Docs

### README.md

```markdown
## Architecture Diagram

![Hub-and-Spoke Topology](diagrams/exports/hub-spoke-topology.drawio.png)

> *Open [hub-spoke-topology.drawio](diagrams/hub-spoke-topology.drawio) in
> [app.diagrams.net](https://app.diagrams.net) to edit.*
```

### GitHub Wiki

Upload the exported PNG/SVG to the wiki repository (`<repo>.wiki.git`) and reference with a relative path:

```markdown
[[/diagrams/exports/hub-spoke-topology.drawio.png|Hub-and-Spoke Topology]]
```

### MkDocs / Docusaurus

```markdown
![Hub-and-Spoke Topology](../diagrams/exports/hub-spoke-topology.drawio.svg)
```

Use SVG for documentation sites — scales perfectly on all screen densities and remains searchable.

---

## Recommended Directory Layout

```
.
├── diagrams/
│   ├── hub-spoke-topology.drawio       # Source .drawio files (committed)
│   ├── landing-zone-design.drawio
│   ├── aks-architecture.drawio
│   └── exports/                        # Generated exports (committed or gitignored)
│       ├── hub-spoke-topology.drawio.png
│       ├── hub-spoke-topology.drawio.svg
│       ├── landing-zone-design.drawio.png
│       └── landing-zone-design.drawio.svg
└── docs/
    └── architecture.md                 # Embeds images from diagrams/exports/
```

**Decision**: commit exports if the repo is documentation-focused (GitHub renders PNG/SVG inline). Gitignore exports if they are always regenerated by CI.

Add to `.gitignore` if regenerating in CI:

```gitignore
diagrams/exports/
```

---

## Preferred MCP Server

- `drawio-http` — validate diagram XML and confirm rendering before export; call `drawio/create_diagram` to test icon resolution.

---

## Output Format

- Export commands for each requested diagram and format
- Batch export script (bash or PowerShell)
- Embedding Markdown snippet for the target docs location
- Optional GitHub Actions workflow for automated export on push


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
