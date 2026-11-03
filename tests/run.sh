#!/usr/bin/env bash
# Checks for the diagrams plugin. Needs bash and python3.
#   tests/run.sh                    offline checks: manifests, skill, render.sh (against a
#                                   fake curl), links, line endings
#   tests/run.sh -v                 also show each passing check
#   tests/run.sh --live             also render every template in examples.md through
#                                   render.sh and https://kroki.io (needs curl and network)
#   tests/run.sh --live --server U  the same against your own Kroki server
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RENDER="$ROOT/skills/diagram/scripts/render.sh"
VERBOSE=0; LIVE=0; SERVER=""
while [ $# -gt 0 ]; do
  case "$1" in
    -v) VERBOSE=1; shift;;
    --live) LIVE=1; shift;;
    --server) SERVER="${2:-}"; shift 2;;
    *) echo "unknown option: $1" >&2; exit 64;;
  esac
done
N_OK=0; N_FAIL=0
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

good() { N_OK=$((N_OK+1)); [ "$VERBOSE" = 1 ] && echo "  ok   $1"; return 0; }
fail() { N_FAIL=$((N_FAIL+1)); echo "  FAIL $1"; [ -n "${2:-}" ] && printf '       %s\n' "$2"; return 0; }
report() { # $1 name, $2 problems (empty = good)
  if [ -z "$2" ]; then good "$1"; else fail "$1" "$2"; fi
}
eq() { [ "$2" = "$3" ] && good "$1" || fail "$1" "expected [$3] got [$2]"; }

echo "manifests"
report "plugin.json and marketplace.json agree, version matches CHANGELOG" "$(cd "$ROOT" && python3 - <<'PY'
import json, re
p = json.load(open(".claude-plugin/plugin.json"))
m = json.load(open(".claude-plugin/marketplace.json"))
top = re.search(r"^## (\S+)", open("CHANGELOG.md").read(), re.M).group(1)
errs = []
# Installs are keyed on the name: renaming would orphan every existing install.
if p.get("name") != "diagrams": errs.append("plugin name changed: %r" % p.get("name"))
if p.get("version") != top: errs.append("plugin.json version %s != CHANGELOG %s" % (p.get("version"), top))
if not re.fullmatch(r"\d+\.\d+\.\d+", p.get("version", "")): errs.append("version is not semver")
if [e.get("name") for e in m.get("plugins", [])] != [p.get("name")]: errs.append("marketplace entry name != plugin name")
if m.get("name", "").startswith(("claude-", "anthropic-")): errs.append("reserved marketplace name prefix")
for k in ("description", "author", "homepage", "repository", "license"):
    if not p.get(k): errs.append("plugin.json missing " + k)
for k, o in p.get("userConfig", {}).items():
    # "options" would stop clients older than 2.1.271 from loading the plugin at all.
    if "options" in o: errs.append("userConfig %s uses options" % k)
    if o.get("required"): errs.append("userConfig %s is required; existing users would be blocked" % k)
print("\n".join(errs))
PY
)"

echo "skill"
SK="$ROOT/skills/diagram/SKILL.md"
report "SKILL.md frontmatter has name: diagram and a description" "$(python3 - "$SK" <<'PY'
import re, sys
t = open(sys.argv[1], encoding="utf-8").read()
m = re.match(r"---\n(.*?)\n---\n", t, re.S)
if not m: print("no frontmatter"); sys.exit()
fm = m.group(1)
if not re.search(r"^name: diagram$", fm, re.M): print("name is not 'diagram' (the folder name)")
d = re.search(r"^description: (.+)$", fm, re.M)
if not d: print("no description")
elif len(d.group(1)) > 1024: print("description over 1024 characters")
PY
)"
# The directory holds any version whose allowed-tools pre-approve broad shell access
# (1.1.0 was held for Bash(curl *), Bash(mkdir *), Bash(ls *)). Only the plugin's own
# script may be pre-approved, by its full ${CLAUDE_PLUGIN_ROOT} path.
report "allowed-tools pre-approves no shell command except the plugin's own script" "$(python3 - "$SK" <<'PY'
import re, sys
fm = re.match(r"---\n(.*?)\n---\n", open(sys.argv[1], encoding="utf-8").read(), re.S).group(1)
line = re.search(r"^allowed-tools: (.+)$", fm, re.M)
tools = re.findall(r"\w+(?:\([^)]*\))?", line.group(1)) if line else []
for t in tools:
    if t in ("Read", "Grep", "Glob", "Write", "Edit"): continue
    if re.fullmatch(r"Bash\(bash \$\{CLAUDE_PLUGIN_ROOT\}/[\w./-]+\.sh:\*\)", t): continue
    print("not allowed: " + t)
PY
)"
report "SKILL.md renders through the plugin's script" "$(grep -q 'bash ${CLAUDE_PLUGIN_ROOT}/skills/diagram/scripts/render.sh ' "$SK" || echo missing)"
report "the script SKILL.md names exists" "$([ -f "$RENDER" ] || echo missing)"
# The directory flags plugins that read values from the user's environment.
report "skill files read no environment variables" "$(grep -rnE 'printenv|\$\{?(KROKI_URL|HOME|USER|PATH)\b' "$ROOT/skills" 2>/dev/null)"

echo "render.sh (fake Kroki)"
R() { PATH="$ROOT/tests/fake:$PATH" bash "$RENDER" "$@"; }
W="$TMP/out dir"; mkdir -p "$W"
printf '@startuml\nA -> B\n@enduml\n' > "$W/seq.puml"
OUT="$(R "$W/seq.puml")"; RC=$?
eq "renders: exit 0" "$RC" 0
report "renders: SVG and PNG written, PNG size reported" "$( [ -f "$W/seq.svg" ] && [ -f "$W/seq.png" ] || echo missing; case "$OUT" in *"seq.png 100x50"*) ;; *) echo "$OUT";; esac)"
report "renders: view line names the PNG" "$(printf '%s\n' "$OUT" | tail -1 | grep -q "^view .*seq.png$" || echo "$OUT")"
report "server defaults to kroki.io" "$(grep -q '^https://kroki.io/plantuml/svg$' "$W/fake-curl.log" || cat "$W/fake-curl.log")"
cp "$W/seq.png" "$TMP/good.png"
printf '@startuml\nFAKE_400\n@enduml\n' > "$W/seq.puml"
OUT="$(R "$W/seq.puml" 2>&1)"; RC=$?
eq "Kroki rejects: exit 2" "$RC" 2
report "Kroki rejects: error text shown" "$(case "$OUT" in *"Syntax Error"*) ;; *) echo "$OUT";; esac)"
report "Kroki rejects: last good image untouched" "$(cmp -s "$W/seq.png" "$TMP/good.png" || echo changed)"
report "Kroki rejects: no temporary folder left" "$(ls -a "$W" | grep '^\.render' )"
printf '@startuml\nFAKE_DOWN\n@enduml\n' > "$W/down.puml"
R "$W/down.puml" >/dev/null 2>&1; eq "server unreachable: exit 3" "$?" 3
printf '@startuml\nFAKE_HTML\n@enduml\n' > "$W/html.puml"
R "$W/html.puml" >/dev/null 2>&1; eq "200 that isn't an image: exit 3" "$?" 3
report "200 that isn't an image: nothing written" "$(ls "$W" | grep '^html\.\(svg\|png\)$')"
printf 'a -> b\n' > "$W/arch.d2"
OUT="$(R "$W/arch.d2")"
report "SVG-only engine: only SVG, view none" "$( [ -f "$W/arch.svg" ] && [ ! -e "$W/arch.png" ] || echo files; printf '%s\n' "$OUT" | tail -1 | grep -q '^view none$' || echo "$OUT")"
R "$W/arch.d2" --formats png >/dev/null 2>&1; eq "SVG-only engine: asking for PNG is a usage error" "$?" 1
printf '{}' > "$W/chart.vl.json"; : > "$W/fake-curl.log"
R "$W/chart.vl.json" >/dev/null
report "double extension: chart.vl.json → vegalite, chart.svg" "$(grep -q '/vegalite/svg$' "$W/fake-curl.log" && [ -f "$W/chart.svg" ] || echo "$(cat "$W/fake-curl.log"; ls "$W")")"
: > "$W/fake-curl.log"; printf '@startuml\nA -> B\n@enduml\n' > "$W/s.puml"
R "$W/s.puml" --server '${user_config.kroki_url}' >/dev/null
report "unexpanded \${...} server value falls back to kroki.io" "$(grep -q '^https://kroki.io/' "$W/fake-curl.log" || cat "$W/fake-curl.log")"
: > "$W/fake-curl.log"; R "$W/s.puml" --server 'http://localhost:8000/' >/dev/null
report "own server used, trailing slash dropped" "$(grep -q '^http://localhost:8000/plantuml/svg$' "$W/fake-curl.log" || cat "$W/fake-curl.log")"
R >/dev/null 2>&1; eq "no source: exit 1" "$?" 1
R "$W/nope.puml" >/dev/null 2>&1; eq "missing source: exit 1" "$?" 1
printf 'x' > "$W/odd.txt"; R "$W/odd.txt" >/dev/null 2>&1; eq "unknown extension: exit 1" "$?" 1
sed 's/$/\r/' "$RENDER" > "$TMP/crlf.sh"
OUT="$(PATH="$ROOT/tests/fake:$PATH" bash "$TMP/crlf.sh" "$W/s.puml" 2>&1)"
report "a copy with Windows line endings still runs" "$(printf '%s\n' "$OUT" | tail -1 | grep -q '^view ' || echo "$OUT")"
if command -v shellcheck >/dev/null 2>&1; then
  report "shellcheck" "$(shellcheck -S warning "$RENDER" "$ROOT/tests/fake/curl" 2>&1)"
fi

echo "docs"
report "relative links resolve" "$(cd "$ROOT" && python3 - <<'PY'
import re, os, glob
bad = []
for md in glob.glob("*.md") + glob.glob("skills/*/*.md"):
    text = re.sub(r"```.*?```", "", open(md, encoding="utf-8").read(), flags=re.S)
    text = re.sub(r"`[^`\n]*`", "", text)  # inline code holds templates like ./{slug}.png
    for link in re.findall(r"\]\(([^)#\s]+)(?:#[^)]*)?\)", text):
        if re.match(r"[a-z]+:", link) or "${" in link: continue
        if not os.path.exists(os.path.normpath(os.path.join(os.path.dirname(md), link))):
            bad.append("%s -> %s" % (md, link))
print("\n".join(bad))
PY
)"
report "README has the one-line marketplace install" "$(grep -q '/plugin install diagrams --marketplace tirandagan/claude-diagrams' "$ROOT/README.md" || echo missing)"

echo "plugin directory rules"
# The directory refuses a repo whose .gitattributes rewrites file contents.
report "no .gitattributes rule the directory rejects" "$(find "$ROOT" -name .gitattributes -not -path '*/.git/*' -exec grep -HnE '(^|[[:space:]])-?(text|eol|crlf|filter|ident|working-tree-encoding|export-ignore|export-subst)([=[:space:]]|$)' {} + 2>/dev/null)"
if git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
  report "every tracked text file uses LF" "$(git -C "$ROOT" ls-files --eol | awk '$2 ~ /crlf/ {print $NF}')"
fi
report "every non-image file is under 256 KiB" "$(find "$ROOT" -type f -not -path '*/.git/*' -size +256k \
  -not -name '*.png' -not -name '*.jpg' -not -name '*.jpeg' -not -name '*.svg' 2>/dev/null)"
report "no top-level bin/ (claude.ai and Cowork won't install a plugin with one)" "$([ -e "$ROOT/bin" ] && echo present)"

if [ "$LIVE" = 1 ]; then
  echo "live renders (${SERVER:-https://kroki.io})"
  L="$TMP/live"; mkdir -p "$L"
  # One file per template in examples.md, named by its Kroki type.
  python3 - "$ROOT/skills/diagram/examples.md" "$L" > "$L/index" <<'PY'
import re, sys
text, out = open(sys.argv[1], encoding="utf-8").read(), sys.argv[2]
ext = {"plantuml": "puml", "mermaid": "mmd", "dot": "dot", "d2": "d2", "erd": "erd", "nwdiag": "nwdiag"}
for i, (head, lang, body) in enumerate(re.findall(r"^## (.+?)\n.*?^```(\w+)\n(.*?)^```", text, re.S | re.M)):
    kind = "c4plantuml" if "C4" in head else {"dot": "graphviz"}.get(lang, lang)
    name = "%d.%s" % (i, ext[lang])
    open("%s/%s" % (out, name), "w", encoding="utf-8").write(body)
    print("%s|%s|%s" % (name, kind, head))
PY
  [ -s "$L/index" ] && good "examples.md has templates" || fail "examples.md has templates"
  while IFS='|' read -r name kind head; do
    OUT="$(bash "$RENDER" "$L/$name" --engine "$kind" --server "$SERVER" 2>&1)"; RC=$?
    if [ "$RC" = 0 ]; then good "$head → $(printf '%s' "$OUT" | grep -c '^wrote') image(s)"
    else fail "$head" "exit $RC: $(printf '%s' "$OUT" | head -c 300)"; fi
  done < "$L/index"
fi

echo
echo "passed $N_OK, failed $N_FAIL"
[ "$N_FAIL" = 0 ]
