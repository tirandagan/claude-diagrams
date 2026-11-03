#!/usr/bin/env bash
# Diagrams plugin by Tiran Dagan, copyright 2026, tiran@tirandagan.com. MIT licensed.
[ -z "${BASH_EXECUTION_STRING-}" ] && case "$(head -n 4 "$0")" in *$'\r'*) exec bash -c "$(tr -d '\r' < "$0")" "$0" "$@";; esac #
#
# Renders one diagram source file through a Kroki server into SVG and, where the
# engine supports it, PNG. Writes the images next to the source.
#
#   bash render.sh SOURCE [--engine ENGINE] [--server URL] [--formats svg,png]
#
#   SOURCE     the diagram source, e.g. diagrams/login-flow.puml
#   --engine   Kroki diagram type (plantuml, mermaid, graphviz, d2, ...). Default: from
#              the file extension.
#   --server   Kroki base URL, e.g. http://localhost:8000. Default: https://kroki.io.
#              Empty values and unexpanded ${...} placeholders count as not given.
#   --formats  comma-separated subset of svg,png. Default: both (SVG only for engines
#              that have no PNG output).
#
# Images are rendered into a temporary folder beside the source and moved into place
# only when every format succeeds, so a failed render never replaces a good image.
#
# Prints at most a few lines: "wrote <file> <size>" per image, then "view <png>" (the
# file to look at) or "view none" (SVG-only engine).
#
# Exit codes:
#   0  rendered
#   1  usage problem (bad option, missing file, unknown engine)
#   2  Kroki rejected the source; its error message is printed. Fix the source.
#   3  server problem (unreachable, timeout, 5xx, unexpected reply). Don't edit the source.
#
# Needs bash (3.2 or later) and curl. Reads only SOURCE; writes only in SOURCE's folder;
# connects only to the Kroki server.

set -u

usage() { echo "usage: render.sh SOURCE [--engine ENGINE] [--server URL] [--formats svg,png]" >&2; exit 1; }
die() { echo "render.sh: $2" >&2; exit "$1"; }

src=""; engine=""; server=""; formats=""
while [ $# -gt 0 ]; do
  case "$1" in
    --engine)  [ $# -ge 2 ] || usage; engine="$2"; shift 2;;
    --server)  [ $# -ge 2 ] || usage; server="$2"; shift 2;;
    --formats) [ $# -ge 2 ] || usage; formats="$2"; shift 2;;
    -h|--help) usage;;
    -*)        die 1 "unknown option: $1";;
    *)         [ -z "$src" ] || die 1 "only one SOURCE file, got a second: $1"; src="$1"; shift;;
  esac
done
[ -n "$src" ] || usage
[ -f "$src" ] || die 1 "no such file: $src"
command -v curl >/dev/null 2>&1 || die 3 "curl is not installed"

# Kroki server: a usable --server value, otherwise the public service.
case "$server" in
  http://*|https://*) server="${server%/}";;
  *)                  server="https://kroki.io";;
esac

# Engine from the file name when not given.
name="$(basename "$src")"
if [ -z "$engine" ]; then
  case "$name" in
    *.puml|*.plantuml|*.pu|*.iuml) engine="plantuml";;
    *.mmd|*.mermaid)               engine="mermaid";;
    *.dot|*.gv)                    engine="graphviz";;
    *.d2)                          engine="d2";;
    *.erd)                         engine="erd";;
    *.dbml)                        engine="dbml";;
    *.vl.json|*.vegalite.json)     engine="vegalite";;
    *.vg.json|*.vega.json)         engine="vega";;
    *.nwdiag)                      engine="nwdiag";;
    *.blockdiag)                   engine="blockdiag";;
    *.seqdiag)                     engine="seqdiag";;
    *.actdiag)                     engine="actdiag";;
    *.rackdiag)                    engine="rackdiag";;
    *.packetdiag)                  engine="packetdiag";;
    *.ditaa)                       engine="ditaa";;
    *.wavedrom.json)               engine="wavedrom";;
    *.bpmn)                        engine="bpmn";;
    *.excalidraw)                  engine="excalidraw";;
    *.nomnoml)                     engine="nomnoml";;
    *.pikchr)                      engine="pikchr";;
    *.wireviz.yml|*.wireviz.yaml)  engine="wireviz";;
    *) die 1 "can't tell the engine from \"$name\"; pass --engine";;
  esac
fi
case "$engine" in
  *[!a-z0-9]*|"") die 1 "engine must be a Kroki diagram type such as plantuml, got: $engine";;
esac

# Engines Kroki can only render to SVG.
case "$engine" in
  d2|dbml|wavedrom|bpmn|excalidraw|nomnoml|pikchr) svg_only=1;;
  *) svg_only=0;;
esac
if [ -z "$formats" ]; then
  if [ "$svg_only" = 1 ]; then formats="svg"; else formats="svg,png"; fi
fi
fmts=""
for f in $(echo "$formats" | tr ',' ' '); do
  case "$f" in
    svg) fmts="$fmts svg";;
    png) [ "$svg_only" = 1 ] && die 1 "$engine has no PNG output on Kroki; use --formats svg"; fmts="$fmts png";;
    *)   die 1 "unknown format: $f (use svg and/or png)";;
  esac
done

# Output names: the source name minus its extension(s).
dir="$(dirname "$src")"
base="$name"
case "$base" in
  *.vl.json|*.vg.json|*.wireviz.yml) base="${base%.*}"; base="${base%.*}";;
  *.vegalite.json|*.vega.json|*.wavedrom.json|*.wireviz.yaml) base="${base%.*}"; base="${base%.*}";;
  *.*) base="${base%.*}";;
esac

tmp="$(mktemp -d "$dir/.render.XXXXXX")" || die 3 "can't create a temporary folder in $dir"
trap 'rm -rf "$tmp"' EXIT

png_size() { # width x height from the PNG header
  od -An -tu1 -j16 -N8 "$1" | awk '{printf "%dx%d", $1*16777216+$2*65536+$3*256+$4, $5*16777216+$6*65536+$7*256+$8}'
}

for f in $fmts; do
  out="$tmp/out.$f"
  code="$(curl -sS --connect-timeout 10 --max-time 60 --retry 2 -o "$out" -w '%{http_code}' -X POST \
    -H 'Content-Type: text/plain' --data-binary @- "$server/$engine/$f" < "$src")"
  rc=$?
  [ "$rc" = 0 ] || die 3 "couldn't reach $server (curl exit $rc)"
  case "$code" in
    200)
      if [ "$f" = png ]; then
        [ "$(od -An -tx1 -N4 "$out" | tr -d ' \n')" = "89504e47" ] || die 3 "$server returned HTTP 200 but not a PNG"
      else
        head -c 4096 "$out" | grep -q '<svg' || die 3 "$server returned HTTP 200 but not an SVG"
      fi;;
    401|403|407)
      die 3 "$server refused the request (HTTP $code); a proxy or the server needs attention";;
    4??)
      echo "Kroki rejected the $engine source (HTTP $code):" >&2
      head -c 2000 "$out" >&2; echo >&2
      exit 2;;
    *)
      die 3 "$server answered HTTP $code: $(head -c 200 "$out" | tr '\n' ' ')";;
  esac
done

view="none"
for f in $fmts; do
  dest="$dir/$base.$f"
  mv -f "$tmp/out.$f" "$dest" || die 3 "can't write $dest"
  if [ "$f" = png ]; then
    echo "wrote $dest $(png_size "$dest")"; view="$dest"
  else
    echo "wrote $dest $(wc -c < "$dest" | tr -d ' ') bytes"
  fi
done
echo "view $view"
