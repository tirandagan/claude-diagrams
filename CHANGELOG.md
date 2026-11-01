# Changelog

## 1.1.0 (2026-11-01)

Polish for the plugin directory listing, a self-hosting option, and render fixes
found by rendering every bundled template through Kroki.

**Fixed**
- The PlantUML activity/workflow template in `examples.md` never rendered: Kroki
  returned `400 This swimlane must be defined at the start of the diagram`. The first
  swimlane is now declared before `start`, and SKILL.md lists the pitfall.
- A failed render was saved as an image. `curl -s` wrote Kroki's error text into the
  PNG and SVG files. The skill now prints the HTTP status of every render, treats
  only `200` as success, reads the error and fixes the source.
- D2 diagrams (SVG only) no longer embed a PNG that doesn't exist in their markdown note.
- SKILL.md said "three output files"; there are four.

**Added**
- `KROKI_URL`: point the skill at your own Kroki server so diagram source never
  leaves your network. Without it, the skill uses `https://kroki.io` as before.
- `.claude-plugin/marketplace.json` (marketplace `tirandagan-diagrams`), so it installs
  in one line: `/plugin install diagrams --marketplace tirandagan/claude-diagrams`.
- Plugin listing fields: display name, author contact, homepage, documentation,
  support and privacy links, a 1024×1024 listing icon with its SVG source in `assets/`.
- `LICENSE` (MIT).
- README: the problem it solves, install paths, example prompts, a "how it works"
  diagram rendered by Kroki, a "What it runs and connects to" disclosure, a privacy
  section, self-hosting, uninstall, and credits.
- `tests/run.sh`: offline checks of the manifests, skill frontmatter, links and line
  endings, plus `--live`, which renders every template in `examples.md` through Kroki.
  CI runs the offline checks.

**Changed**
- The skill writes the diagram source straight to `diagrams/{slug}.{ext}` and renders
  from it, instead of a temporary file. Refinements edit that file and re-render.
- The skill renders SVG first, then PNG, and tells you which Kroki server it used.
- Broader skill description, so it triggers on "draw", "visualize", state machines,
  class diagrams and diagrams of your own code.

## 1.0.0 (2026-03-11)

- First release: the `diagram` skill, 20+ diagram types through Kroki.io, and
  templates for PlantUML, C4, Mermaid, GraphViz, D2, ERD and NwDiag.
