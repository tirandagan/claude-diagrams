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

### Option A: Quick install (recommended)

This method downloads the plugin and makes it available every time you use Claude Code.

**Step 1: Open your terminal**

- **Mac**: Open the **Terminal** app (search for "Terminal" in Spotlight)
- **Windows**: Open **Git Bash**, **WSL**, or **PowerShell**
- **Linux**: Open your terminal application

**Step 2: Download the plugin**

Copy and paste this command into your terminal and press Enter:

```bash
git clone https://github.com/tirandagan/claude-diagrams.git ~/.claude-plugins/claude-diagrams
```

This downloads the plugin to a folder on your computer. If you see an error about `git` not being found, you need to [install Git](https://git-scm.com/downloads) first.

**Step 3: Start Claude Code with the plugin**

```bash
claude --plugin-dir ~/.claude-plugins/claude-diagrams
```

That's it! The `/diagrams:diagram` command is now available in your Claude Code session.

> **Tip:** You'll need to include `--plugin-dir ~/.claude-plugins/claude-diagrams` each time you start Claude Code. To avoid this, see Option B below.

### Option B: Install via marketplace (permanent)

If this plugin is available in a Claude Code marketplace, you can install it permanently so it loads automatically every session:

```bash
claude plugins install diagrams
```

If the plugin isn't found, you can add this repository as a marketplace source first:

```bash
claude plugins marketplace add https://github.com/tirandagan/claude-diagrams
claude plugins install diagrams
```

### Updating the plugin

To get the latest version:

```bash
cd ~/.claude-plugins/claude-diagrams && git pull
```

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
