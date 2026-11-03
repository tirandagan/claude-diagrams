# Changelog

## 1.1.2 (2026-11-02)

**Changed**
- The plugin is listed as **Diagram Generator** instead of Diagrams. Its install name,
  `diagrams`, and the `/diagrams:diagram` command stay the same, so existing installs
  keep working.
- A short description (under 200 characters) for the plugin directory listing.

**Added**
- A user guide, [docs/USER_GUIDE.md](docs/USER_GUIDE.md): install, writing a good
  request, every diagram type, refining, settings, privacy and troubleshooting. The
  plugin's documentation link points to it.
- A credit banner. Each time the skill runs, Claude opens its reply with a short boxed
  banner: Diagrams, written by Tiran Dagan (tiran@tirandagan.com), copyright 2026.

**Tests**
- A check that the banner keeps its credit and that its box lines up.
- Checks that the documentation link names a file in the repo, that the guide's links
  resolve, and that the description stays short enough for the listing.
- The fake curl no longer sets a variable it never uses (shellcheck SC2034, which
  failed CI on 1.1.1).

## 1.1.1 (2026-11-02)

Clears the plugin directory's policy hold on 1.1.0: "Pre-approves broad shell access
in allowed-tools".

**Changed**
- The skill pre-approves exactly one command, the plugin's own render script, by its
  full path. 1.1.0 pre-approved `curl`, `mkdir` and `ls` with any arguments.
- New `skills/diagram/scripts/render.sh` (bash + curl): sends the source to Kroki,
  checks every reply, and saves the SVG and PNG. It renders into a temporary folder and
  moves the images into place only when every format succeeds, so a failed re-render no
  longer replaces the last good image with error text. Exit codes tell Claude whether
  to fix the source (2) or report a server problem (3).
- The Kroki server is now a plugin setting (**Kroki server**, `kroki_url`), set with
  `/plugin configure` or `/config`. The skill no longer reads the `KROKI_URL`
  environment variable. Empty means kroki.io, as before.
- Claude now looks at the rendered PNG and fixes clipped text or layout problems before
  presenting the diagram.

**Fixed**
- SKILL.md said DBML supports PNG. Kroki renders `dbml`, `wavedrom`, `bpmn`,
  `excalidraw`, `nomnoml` and `pikchr` (like `d2`) to SVG only; the script and the skill
  now say so.
- Templates no longer name the Segoe UI font, which Kroki's servers don't have. In SVGs
  it made viewers without Segoe UI (macOS, Linux) fall back to a serif font. PlantUML
  now uses a plain sans-serif; GraphViz names Arial, Helvetica, sans-serif.
- `Edit` is pre-approved, so refining a diagram edits its source without a prompt.

**Tests**
- `render.sh` is tested offline against a fake curl: exit codes, the last good image
  surviving a failed render, SVG-only engines, server fallback, Windows line endings.
- A check that `allowed-tools` pre-approves no shell command except the plugin's own
  script, and that the skill reads no environment variables.

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
