# Diagrams Plugin for Claude Code

Generate professional diagrams from natural language descriptions using [Kroki.io](https://kroki.io/).

## What it does

Describe what you want to visualize and the plugin will:

1. **Analyze** your description to identify the best diagram type
2. **Generate** a professionally styled diagram script (PlantUML, Mermaid, GraphViz, D2, etc.)
3. **Render** both PNG and SVG via the Kroki.io free API
4. **Save** four files: markdown rationale, PNG, SVG, and the source script

## Supported diagram types

| Category | Types |
|---|---|
| **UML** | Sequence, Activity, Class, State, Use Case, Deployment (PlantUML) |
| **Architecture** | C4 Model, D2, Block Diagrams |
| **Data** | ERD, DBML, GraphViz dependency graphs |
| **Flow** | Flowcharts (Mermaid), Decision Trees |
| **Infrastructure** | Network (NwDiag), Rack, Packet |
| **Project** | Gantt Charts, Mind Maps |
| **Other** | WaveDrom, WireViz, Vega-Lite, Ditaa, and more |

## Installation

### Local testing

```bash
claude --plugin-dir ~/dev/claude_diagrams
```

### Install to user scope

Add to a marketplace or install directly via `--plugin-dir`.

## Usage

```
/diagrams:diagram describe your diagram here
```

### Examples

```
/diagrams:diagram user authentication flow with OAuth2 for a web application
/diagrams:diagram database schema for an e-commerce platform with users, products, and orders
/diagrams:diagram CI/CD pipeline from code push to production deployment
/diagrams:diagram microservices architecture for a payment processing system
```

## Output

All files are saved to a `diagrams/` directory in your current project:

| File | Description |
|---|---|
| `{slug}.md` | Markdown with diagram rationale and design decisions |
| `{slug}.png` | Rendered PNG image |
| `{slug}.svg` | Rendered SVG image |
| `{slug}.{ext}` | Source script (`.puml`, `.mmd`, `.dot`, `.d2`, etc.) |

## Requirements

- Claude Code v1.0.33+
- Internet access (for Kroki.io API calls)
- `curl` available in PATH

## License

MIT
