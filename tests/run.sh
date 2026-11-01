#!/usr/bin/env bash
# Checks for the diagrams plugin. Needs bash and python3.
#   tests/run.sh          offline checks: manifests, skill frontmatter, links, line endings
#   tests/run.sh -v       also show each passing check
#   tests/run.sh --live   also render every template in examples.md through Kroki
#                         (uses $KROKI_URL if set, otherwise https://kroki.io; needs curl)
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERBOSE=0; LIVE=0
for a in "$@"; do case "$a" in -v) VERBOSE=1;; --live) LIVE=1;; *) echo "unknown option: $a" >&2; exit 64;; esac; done
N_OK=0; N_FAIL=0

good() { N_OK=$((N_OK+1)); [ "$VERBOSE" = 1 ] && echo "  ok   $1"; return 0; }
fail() { N_FAIL=$((N_FAIL+1)); echo "  FAIL $1"; [ -n "${2:-}" ] && printf '       %s\n' "$2"; return 0; }
report() { # $1 name, $2 problems (empty = good)
  if [ -z "$2" ]; then good "$1"; else fail "$1" "$2"; fi
}

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
report "SKILL.md describes the KROKI_URL override and HTTP status check" "$(grep -q 'printenv KROKI_URL' "$SK" && grep -q 'http_code' "$SK" || echo missing)"

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

if [ "$LIVE" = 1 ]; then
  BASE="${KROKI_URL:-https://kroki.io}"; BASE="${BASE%/}"
  echo "live renders ($BASE)"
  TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
  # Split examples.md into one file per template: "<n>|<kroki type>|<heading>" lines.
  python3 - "$ROOT/skills/diagram/examples.md" "$TMP" > "$TMP/index" <<'PY'
import re, sys
text, out = open(sys.argv[1], encoding="utf-8").read(), sys.argv[2]
api = {"plantuml": "plantuml", "mermaid": "mermaid", "dot": "graphviz", "d2": "d2", "erd": "erd", "nwdiag": "nwdiag"}
for i, (head, lang, body) in enumerate(re.findall(r"^## (.+?)\n.*?^```(\w+)\n(.*?)^```", text, re.S | re.M)):
    kind = "c4plantuml" if "C4" in head else api[lang]
    open("%s/%d.src" % (out, i), "w", encoding="utf-8").write(body)
    print("%d|%s|%s" % (i, kind, head))
PY
  [ -s "$TMP/index" ] && good "examples.md has templates" || fail "examples.md has templates"
  while IFS='|' read -r i kind head; do
    fmts="svg png"; [ "$kind" = d2 ] && fmts="svg"
    for f in $fmts; do
      code="$(curl -sS -o "$TMP/$i.$f" -w '%{http_code}' -X POST "$BASE/$kind/$f" \
        -H 'Content-Type: text/plain' --data-binary @"$TMP/$i.src" 2>&1)"
      if [ "$code" = 200 ]; then good "$head → $f"
      else fail "$head → $f" "HTTP $code: $(head -c 200 "$TMP/$i.$f" 2>/dev/null)"; fi
    done
  done < "$TMP/index"
fi

echo
echo "passed $N_OK, failed $N_FAIL"
[ "$N_FAIL" = 0 ]
