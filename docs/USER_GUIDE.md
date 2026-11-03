# Diagram Generator: User Guide

Diagram Generator is a Claude Code plugin that turns a plain-English description, or
your own code and documents, into a finished diagram. Claude picks the right diagram
type, writes the source, renders it to SVG and PNG, looks at the result, and saves
everything to a `diagrams/` folder in your project.

- Plugin name: `diagrams` (what `/plugin` and install commands use)
- Command: `/diagrams:diagram`
- Author: Tiran Dagan, tiran@tirandagan.com · MIT licensed · copyright 2026

## Contents

1. [Install](#1-install)
2. [Make your first diagram](#2-make-your-first-diagram)
3. [Ask for a good diagram](#3-ask-for-a-good-diagram)
4. [Diagram types](#4-diagram-types)
5. [Diagrams of your code and documents](#5-diagrams-of-your-code-and-documents)
6. [Change a diagram](#6-change-a-diagram)
7. [What gets saved](#7-what-gets-saved)
8. [Settings: your own Kroki server](#8-settings-your-own-kroki-server)
9. [What it runs, reads and sends](#9-what-it-runs-reads-and-sends)
10. [Troubleshooting](#10-troubleshooting)
11. [Uninstall](#11-uninstall)
12. [Questions](#12-questions)

## 1. Install

**From Anthropic's plugin directory:** open the
[Diagram Generator listing](https://claude.ai/customize/plugins/id/788c2450-fe4e-4524-b77e-0772cba1ee5c%40anthropic-plugin-directory)
and click **Add**.

**From this repo's marketplace,** in Claude Code 2.1.275 or later:

```
/plugin install diagrams --marketplace tirandagan/claude-diagrams
```

On older versions, run these two commands instead:

```
/plugin marketplace add tirandagan/claude-diagrams
/plugin install diagrams@tirandagan-diagrams
```

**From a clone,** for one session at a time:

```bash
git clone https://github.com/tirandagan/claude-diagrams.git ~/.claude-plugins/claude-diagrams
claude --plugin-dir ~/.claude-plugins/claude-diagrams
```

Start a new chat after installing. To check it's there, type `/diagrams` and
`/diagrams:diagram` should appear in the list.

You also need `bash` and `curl`. macOS and Linux have both; on Windows, use Git Bash
or WSL.

## 2. Make your first diagram

There are two ways to start. Either type the command and a description:

```
/diagrams:diagram user sign-in with email and password, including the locked-account case
```

Or just ask in plain words, and Claude uses the skill on its own:

> Draw a flowchart of how a support ticket gets escalated.

Each time the skill runs, Claude opens with a short credit banner naming the plugin and
its author. Then it:

1. **Works out what you're describing:** the parts, how they connect, and whether it's
   a flow, a structure, a hierarchy, a timeline or a network.
2. **Picks the diagram type** that fits (see [Diagram types](#4-diagram-types)).
3. **Writes the source** in that type's language, with a title, labelled arrows,
   grouping, and colour that means something.
4. **Renders it** through Kroki into SVG and, for most types, PNG.
5. **Looks at the PNG** and fixes clipped text, overlaps or a layout that's too wide,
   then renders again.
6. **Saves four files** to `diagrams/` and shows you the result, with a line saying which
   Kroki server rendered it.

## 3. Ask for a good diagram

You'll get a better diagram on the first try if your request says:

- **What it's for:** "for a design review", "to explain to new hires".
- **What's in it:** the people, systems, steps or tables that must appear.
- **How they connect:** who calls whom, what happens after what, what belongs to what.
- **The type, if you have one in mind:** "as a sequence diagram", "as a C4 container
  view", "as an ERD". Otherwise Claude chooses.

| You ask | You get |
|---|---|
| "Sequence diagram of OAuth2 login with Google for our web app" | A PlantUML sequence diagram with numbered messages and the success and failure paths |
| "ERD for an online store: customers, orders, products, categories" | An entity-relationship diagram with keys and cardinality |
| "Architecture of a React app, a Node API, Postgres and Redis" | A C4 or D2 architecture diagram with layers and labelled connections |
| "Gantt chart for a six-week launch plan" | A Mermaid Gantt chart with sections and dependencies |
| "State machine for an order: placed, paid, shipped, delivered, cancelled" | A PlantUML state diagram |

## 4. Diagram types

| What you're showing | Diagram type | Source file | PNG |
|---|---|---|---|
| Workflows and business processes | Activity diagram (PlantUML) | `.puml` | Yes |
| Step-by-step flows and decisions | Flowchart (Mermaid) | `.mmd` | Yes |
| API calls and service interactions | Sequence diagram (PlantUML) | `.puml` | Yes |
| Software architecture | C4 model (PlantUML) or D2 | `.puml`, `.d2` | C4 yes, D2 no |
| Classes and inheritance | Class diagram (PlantUML) | `.puml` | Yes |
| States and lifecycles | State diagram (PlantUML) | `.puml` | Yes |
| Database schemas | ERD or DBML | `.erd`, `.dbml` | ERD yes, DBML no |
| Networks and infrastructure | NwDiag network diagram | `.nwdiag` | Yes |
| Dependency graphs and trees | GraphViz | `.dot` | Yes |
| Mind maps | Mind map (PlantUML) | `.puml` | Yes |
| Timelines and schedules | Gantt chart (Mermaid) | `.mmd` | Yes |
| Charts of numbers | Vega-Lite | `.json` | Yes |
| Also available | BlockDiag, RackDiag, PacketDiag, WaveDrom, WireViz, Ditaa, use case and deployment diagrams | | Most yes |

"PNG: no" means the type renders to SVG only. That's true of D2, DBML, WaveDrom, BPMN,
Excalidraw, Nomnoml and Pikchr. Kroki doesn't make PNGs for them.

## 5. Diagrams of your code and documents

Name the files or folders and say what to draw:

- "Draw the request flow through `src/api/` as a sequence diagram."
- "Make an ERD from the models in `app/models.py`."
- "Visualize the services in `docker-compose.yml` as an architecture diagram."
- "Turn the steps in `docs/onboarding.md` into a flowchart."

Claude reads what you name before designing, so the diagram can use the real names
from your code, such as services, tables and functions. Point it at the
smallest part that answers your question: a diagram of one module reads better than a
diagram of a whole repo.

## 6. Change a diagram

Ask for changes in the same chat, and Claude edits the saved source and re-renders the
same files:

- "Make it top to bottom."
- "Add a cache between the API and the database."
- "The diagram is too wide. Split the payment part into its own diagram."
- "Use a sequence diagram instead."

In a later chat, name the file: "Update `diagrams/user-auth-flow.puml` to add
two-factor login." You can also edit the source file yourself and ask Claude to render
it again.

## 7. What gets saved

Every diagram is saved to `diagrams/` in the folder you're working in, under a short
name taken from your description (for example `user-auth-flow`):

| File | Contents |
|---|---|
| `user-auth-flow.puml` (or `.mmd`, `.dot`, `.d2` and so on) | The editable source |
| `user-auth-flow.svg` | The image, scalable, for docs and the web |
| `user-auth-flow.png` | The image as a picture file (not for SVG-only types) |
| `user-auth-flow.md` | What the diagram shows, why this type, the design choices, and the image embedded |

- **Keep the source in version control.** It's small, readable and re-renders the same
  way anywhere.
- **A failed render never overwrites a good image.** Images are only replaced when every
  format renders successfully.

## 8. Settings: your own Kroki server

By default, diagrams are rendered by the free public Kroki service at
[kroki.io](https://kroki.io/). To render on your own machine or network instead, run
Kroki yourself:

```bash
docker run -d -p 8000:8000 yuzutech/kroki
```

Then set the plugin's **Kroki server** setting to `http://localhost:8000`. In Claude
Code, run `/plugin configure diagrams@tirandagan-diagrams` or open `/config`. If you
installed from the directory, use the plugin name `/plugin` shows for it. Leave the
setting empty to go back to kroki.io.

Mermaid, BPMN and Excalidraw need extra companion containers. Kroki's
[Docker guide](https://docs.kroki.io/kroki/setup/use-docker-or-podman/) has a compose
file with all of them.

## 9. What it runs, reads and sends

- **Runs:** one readable script,
  [`skills/diagram/scripts/render.sh`](../skills/diagram/scripts/render.sh), which
  uses `curl` to send a diagram's source to Kroki and saves the images. It's the only
  command the skill runs without asking you. There are no hooks, no MCP servers and
  nothing running in the background.
- **Reads:** files in your project only when a diagram needs them, and the **Kroki
  server** setting. Nothing from your environment variables.
- **Writes:** the four files per diagram, in `diagrams/`.
- **Connects to:** `https://kroki.io`, or the Kroki server you set.
- **Sends:** the diagram source text and nothing else: no project files, paths or
  account details, no telemetry, nothing to the author.

kroki.io is a third-party service this plugin doesn't run or control. If a diagram
describes something confidential, such as internal hostnames or a database schema,
use your own Kroki server (above) so the source never leaves your network.

## 10. Troubleshooting

**Claude says Kroki rejected the source.** Kroki couldn't parse the diagram and said
where. Claude reads the error, fixes the source and renders again on its own. If it
keeps failing, ask for a different diagram type.

**Claude says the Kroki server couldn't be reached.** Claude doesn't change your
diagram in this case, because the problem is the connection. Check that you're online
and that kroki.io opens in a browser. If you set your own server, check that it's
running at the address in the **Kroki server** setting.

**It fails behind a company network.** Some proxies answer with a login page instead of
an image. The script checks every reply, so you'll see a server error rather than a
broken image. Use your own Kroki server, or ask your network team to allow kroki.io.

**There's no PNG.** The diagram type renders to SVG only (see
[Diagram types](#4-diagram-types)). Open the SVG in a browser, or ask for a type that
has PNG output.

**Claude asks permission to run a command.** The render script runs without asking.
Any other command, such as rendering by hand with `curl` where the script can't run,
asks first. That's expected.

**Claude answered without making a diagram.** Start the request with
`/diagrams:diagram` to run the skill directly.

**The diagram is crowded or too wide.** Ask Claude to split it, for example into an
overview and one diagram per part, or to show less detail.

## 11. Uninstall

- Installed from the directory: remove it where you added it, or from `/plugin` in
  Claude Code.
- Installed from this repo's marketplace: `/plugin uninstall diagrams@tirandagan-diagrams`.
- From a clone: delete `~/.claude-plugins/claude-diagrams`.

Diagrams you've already made stay in your projects' `diagrams/` folders.

## 12. Questions

**Does it cost anything?** The plugin is free, and so is the public kroki.io service.
Making a diagram uses your normal Claude usage.

**Can I use it offline?** Yes, with your own Kroki server on your machine
(see [Settings](#8-settings-your-own-kroki-server)).

**Who owns the diagrams?** You do. The plugin is MIT licensed, and the diagrams it
makes for you are yours to use however you like.

**Where do I report a problem or ask for a feature?** Open an issue at
[github.com/tirandagan/claude-diagrams/issues](https://github.com/tirandagan/claude-diagrams/issues).

---

Diagram Generator is written by Tiran Dagan (tiran@tirandagan.com), copyright 2026,
MIT licensed. Not affiliated with or endorsed by Anthropic or the Kroki project.
