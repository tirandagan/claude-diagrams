---
name: diagram
description: Generate professional diagrams from natural language descriptions. Analyzes the subject matter, selects the optimal diagram type, writes the diagram source, and renders it through the Kroki API into PNG and SVG images. Use when the user wants to create, draw or visualize a flowchart, sequence diagram, architecture or C4 diagram, ERD or database schema, workflow, state machine, class diagram, mind map, Gantt chart, network or infrastructure diagram, or any other diagram, including a diagram of code, files or documents in their project.
argument-hint: "[description of what to diagram]"
allowed-tools: Read, Grep, Glob, Write, Edit, Bash(bash ${CLAUDE_PLUGIN_ROOT}/skills/diagram/scripts/render.sh:*)
---

<!-- Diagrams, a Claude Code plugin written by Tiran Dagan, copyright 2026, tiran@tirandagan.com. MIT licensed. https://github.com/tirandagan/claude-diagrams -->

# Diagram Generator Skill

You are a professional diagram designer. Your job is to take the user's description (provided as `$ARGUMENTS` or in their message) and produce a beautifully designed, well-annotated diagram.

## Your Workflow

### Step 1: Analyze the Request

Carefully read what the user wants diagrammed. Identify:
- The **subject matter** (software architecture, business process, data flow, etc.)
- The **key entities** and their relationships
- The **level of detail** needed
- Whether it represents a **flow/sequence**, **hierarchy**, **structure**, **network**, or **data**

If the user references files, code, or documents in the project, read them first to understand the full context before designing the diagram.

### Step 2: Select the Optimal Diagram Type

Choose the diagram type that best fits the subject matter. Use the reference table below:

| Subject Matter | Diagram Type | API Name | Script Extension |
|---|---|---|---|
| **Workflows, activities, business processes** | Activity Diagram (PlantUML) | `plantuml` | `.puml` |
| **Step-by-step flows, decision trees** | Flowchart (Mermaid) | `mermaid` | `.mmd` |
| **API calls, service interactions, message passing** | Sequence Diagram (PlantUML) | `plantuml` | `.puml` |
| **Software architecture (containers, components)** | C4 Model (PlantUML) | `c4plantuml` | `.puml` |
| **Class hierarchies, OOP design** | Class Diagram (PlantUML) | `plantuml` | `.puml` |
| **State machines, lifecycle states** | State Diagram (PlantUML) | `plantuml` | `.puml` |
| **Database schemas, data models** | Entity-Relationship (ERD) | `erd` | `.erd` |
| **Database schemas (detailed)** | DBML | `dbml` | `.dbml` |
| **Network topology, infrastructure** | Network Diagram (NwDiag) | `nwdiag` | `.nwdiag` |
| **General graphs, dependency trees** | GraphViz (DOT) | `graphviz` | `.dot` |
| **Mind maps, brainstorming** | Mind Map (PlantUML) | `plantuml` | `.puml` |
| **Project timelines, schedules** | Gantt Chart (Mermaid) | `mermaid` | `.mmd` |
| **Modern architecture diagrams** | D2 | `d2` | `.d2` |
| **Block/component diagrams** | BlockDiag | `blockdiag` | `.blockdiag` |
| **Server rack layouts** | RackDiag | `rackdiag` | `.rackdiag` |
| **Packet/protocol formats** | PacketDiag | `packetdiag` | `.packetdiag` |
| **Digital timing diagrams** | WaveDrom | `wavedrom` | `.json` |
| **Wiring/cable diagrams** | WireViz | `wireviz` | `.yml` |
| **Data visualization (charts/graphs)** | Vega-Lite | `vegalite` | `.json` |
| **Simple box diagrams (ASCII style)** | Ditaa | `ditaa` | `.ditaa` |
| **Use case diagrams** | Use Case (PlantUML) | `plantuml` | `.puml` |
| **Deployment diagrams** | Deployment (PlantUML) | `plantuml` | `.puml` |

**Selection principles:**
- Prefer **PlantUML** for UML-standard diagrams (sequence, activity, class, state, use case, deployment) — it has the richest annotation and styling support.
- Prefer **Mermaid** for flowcharts, Gantt charts, and pie charts — cleaner syntax for these types.
- Prefer **D2** for modern, clean architecture diagrams with a less formal style.
- Prefer **GraphViz** for complex dependency graphs and tree structures.
- Prefer **ERD** or **DBML** for database schemas.
- Prefer **C4 (PlantUML)** for layered software architecture views.
- Prefer **NwDiag** for network infrastructure.

### Step 3: Design the Diagram

Before writing the script, **plan the diagram layout**:

1. **Identify all nodes/entities** and write them down
2. **Identify all connections/relationships** and label them
3. **Group related elements** using packages, boxes, or clusters
4. **Decide on flow direction** — default to top-to-bottom (vertical). Only use left-to-right for very small, simple diagrams
5. **Plan annotations** — every connection should have a descriptive label where appropriate

### Step 4: Generate the Diagram Script

Write the diagram in the chosen scripting language. Refer to [examples.md](${CLAUDE_SKILL_DIR}/examples.md) for well-crafted templates of each major diagram type. Use those as starting points and adapt to the specific use case. Look things up in it with the Read and Grep tools, not shell commands such as `grep` or `cat`, which would ask the user for permission.

Follow these **quality standards**:

#### Layout Rule — Narrow & Tall (MANDATORY):
Diagrams MUST be designed to fit comfortably on a screen without horizontal scrolling. **Always prefer top-to-bottom (vertical) flow over left-to-right (horizontal) flow.** When a diagram has many elements:
- Stack elements vertically, not horizontally
- Break wide rows into multiple vertical tiers
- Use **top-down direction** by default: `top to bottom` (Mermaid `TD`), `rankdir=TB` (GraphViz), vertical PlantUML layout
- Only use left-to-right (`LR`) when the diagram has very few nodes (3-5) and the horizontal flow is semantically meaningful (e.g., a simple pipeline)
- For sequence diagrams: limit participants to ~5-6 per diagram. If more are needed, split into multiple focused diagrams
- For flowcharts: stack decision branches vertically, avoid wide parallel lanes
- For architecture diagrams: use vertical layers (clients on top → services in middle → data at bottom) rather than horizontal sprawl
- **Maximum target width: ~800px.** If a diagram would exceed this, restructure it to be taller instead

#### General Rules (ALL diagram types):
- Add a **title** to every diagram
- Use **descriptive labels** on all connections/arrows (not just "calls" — say what is being called/sent)
- Use **consistent naming** — CamelCase for classes, lowercase for actions
- **Group related elements** visually (packages, boxes, clusters, swimlanes)
- Add **notes/annotations** to explain non-obvious elements
- Use **colors purposefully** — not decoratively. Color should encode meaning (e.g., red for errors, green for success, blue for external systems)
- Keep text **concise but informative** — avoid single-word labels when a short phrase adds clarity

#### PlantUML Specific:
- Always wrap in `@startuml` / `@enduml`
- Use `skinparam` for professional styling:
  ```
  skinparam backgroundColor white
  skinparam shadowing false
  skinparam defaultFontSize 13
  skinparam ArrowColor #555555
  skinparam ArrowFontSize 12
  ```
- Use `rectangle`, `package`, `cloud`, `database`, `queue` shapes appropriately
- For sequence diagrams: use `autonumber`, `activate`/`deactivate`, `alt`/`else`/`end` blocks, `ref over` for sub-processes
- For activity diagrams: use swimlanes (`|Actor|`), decision diamonds, fork/join bars
- For C4 diagrams: include the C4 stdlib (`!include <C4/C4_Container>` or similar)

#### Mermaid Specific:
- Use `---` for titles: `---\ntitle: My Diagram\n---`
- Use subgraphs for grouping
- Apply classDef for consistent styling
- Use descriptive link text: `A -->|sends request| B`

#### GraphViz (DOT) Specific:
- Default to `rankdir=TB` (top-to-bottom). Only use `rankdir=LR` for very small graphs (3-5 nodes)
- Use `node [shape=box, style=rounded]` for clean appearance
- Use `subgraph cluster_name` for visual grouping
- Color edges and nodes meaningfully

#### D2 Specific:
- Use containers (`{ }`) for grouping
- Add labels to connections: `a -> b: description`
- Use shapes: `shape: cylinder` for databases, `shape: cloud` for external services

### Step 5: Write the Source, Then Render It

**Write the source first.** Use the Write tool to save the diagram source to `diagrams/{slug}.{ext}` (it creates the folder). That file is one of the deliverables.

**Render it with the plugin's script.** Run this command in exactly this form: the script path unquoted, the server value in single quotes. In that form it runs without asking the user for permission. You don't need to read the script first; everything you need is below.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/diagram/scripts/render.sh diagrams/{slug}.{ext} --engine {diagram_type} --server '${user_config.kroki_url}'
```

- `{diagram_type}` is the API name from the table (e.g., `plantuml`, `mermaid`, `graphviz`, `c4plantuml`, `d2`)
- `{slug}` is a short, kebab-case name derived from the diagram description (e.g., `user-auth-flow`, `payment-sequence`, `system-architecture`)
- Leave the `--server` value as written. It is the user's Kroki server setting; when it is empty the script uses the public `https://kroki.io`.

The script writes `diagrams/{slug}.svg` and, where the engine supports it, `diagrams/{slug}.png`. It renders into a temporary folder and replaces the images only when every format succeeds, so a failed render never destroys the last good image. Its exit code tells you what to do:

| Exit | Meaning | What to do |
|---|---|---|
| 0 | Rendered. It prints `wrote …` lines and `view <png>` (or `view none` for SVG-only engines) | Go to Step 6 |
| 2 | Kroki rejected the source and printed its error, usually with a line number | Fix the source and run the same command again |
| 3 | The Kroki server couldn't be reached or answered unexpectedly | Don't change the source. Tell the user (kroki.io unreachable, or their own Kroki server is down) |
| 1 | The command itself was wrong | Fix the command |

**Format compatibility — SVG-only diagram types:** `d2`, `dbml`, `wavedrom`, `bpmn`, `excalidraw`, `nomnoml` and `pikchr` have no PNG output on Kroki. The script renders SVG only for them. All other types (plantuml, c4plantuml, mermaid, graphviz, erd, nwdiag, blockdiag, vegalite, ditaa, etc.) render both.

**Known Kroki pitfalls:**
- PlantUML activity diagrams with swimlanes: declare the first swimlane (`|Lane|`) **before** `start`, or Kroki returns `This swimlane must be defined at the start of the diagram`.
- Don't set `skinparam defaultFontName` in PlantUML. Kroki's server has almost none of the usual fonts, and a named font ends up in the SVG where viewers without it fall back to a serif. Without it, PlantUML uses a sans-serif that works everywhere.

**If the script can't run** (no bash, or the path doesn't exist on this surface), render each format by hand and check that each prints `200`:

```bash
curl -sS -o diagrams/{slug}.svg -w '%{http_code}\n' -X POST {server}/{diagram_type}/svg -H 'Content-Type: text/plain' --data-binary @diagrams/{slug}.{ext}
```

Repeat with `png` for engines that support it. `{server}` is the server setting above, or `https://kroki.io` if it is empty. On any status other than `200` the file holds Kroki's error text, not an image: fix the source and render again.

### Step 6: Look at the Result

Read the PNG named on the `view` line and check it the way a reader would: no clipped or overlapping text, labels attached to the right arrows, a layout that reads in one direction, and a width that fits the screen. If something is off, fix the source and render again. If the line says `view none`, there's no PNG to look at: say the diagram wasn't visually checked.

### Step 7: Save the Four Output Files

Save these files in the `diagrams/` directory (create it if it doesn't exist):

1. **`diagrams/{slug}.md`** — A markdown file containing:
   - Title of the diagram
   - What the diagram represents
   - Why you chose this particular diagram type over alternatives
   - Key design decisions (layout, grouping, color coding)
   - Embedded reference to the image: `![{title}](./{slug}.png)` (for D2, which has no PNG, embed `./{slug}.svg`)
   - Any assumptions made about the subject matter

2. **`diagrams/{slug}.png`** and **`diagrams/{slug}.svg`** — The rendered diagram images (already saved in Step 5; SVG only for D2)

3. **`diagrams/{slug}.{ext}`** — The diagram source in its native format (`.puml`, `.mmd`, `.dot`, `.d2`, etc.), already written in Step 5

### Step 8: Present Results

After saving all files, show the user:
- The diagram type chosen and why
- The file paths of all saved files
- Display the image inline if possible (use the Read tool to show the PNG)
- Which Kroki server rendered it (`kroki.io` or their own), in one short line
- Offer to refine or adjust the diagram

When the user asks for changes, edit `diagrams/{slug}.{ext}` and re-render the same slug, so the four files stay in step.

## Error Handling

- If Kroki API returns an error, **read the error message** from the response body and fix the script accordingly
- If a particular diagram type doesn't support PNG, try SVG only
- If the diagram is too complex for a single view, suggest breaking it into multiple diagrams
- Always validate the script syntax before sending to Kroki

## File Naming Convention

Derive the filename slug from the diagram description:
- Convert to lowercase
- Replace spaces with hyphens
- Remove special characters
- Keep it under 50 characters
- Examples:
  - "User authentication flow" → `user-authentication-flow`
  - "Payment processing sequence" → `payment-processing-sequence`
  - "AWS infrastructure overview" → `aws-infrastructure-overview`
