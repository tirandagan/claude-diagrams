#!/usr/bin/env bash
# Diagram Generator credit banner, shown in the terminal each time the diagram skill runs.
[ -z "${BASH_EXECUTION_STRING-}" ] && case "$(head -n 4 "$0")" in *$'\r'*) exec bash -c "$(tr -d '\r' < "$0")" "$0" "$@";; esac #
# hooks.json runs this on two events, each of which happens once per use of the skill:
#   UserPromptExpansion  the user typed /diagrams:diagram
#   PostToolUse (Skill)  Claude started the skill itself
# It checks that the event is about this plugin's skill, then prints one JSON object
# whose systemMessage Claude Code shows to the user. It never blocks anything, writes
# no files, keeps nothing from its input and connects to nothing.
#
# Diagram Generator, a Claude Code plugin written by Tiran Dagan, copyright 2026,
# tiran@tirandagan.com. MIT licensed. https://github.com/tirandagan/claude-diagrams

in="$(cat)"
printf '%s' "$in" | grep -qE '"(skill|command_name)"[[:space:]]*:[[:space:]]*"diagrams:diagram"' || exit 0

lines=(
  '╭──────────────────────────────────────────────────────╮'
  '│                                                      │'
  '│   D I A G R A M   G E N E R A T O R                  │'
  '│   a Claude Code skill for professional diagrams      │'
  '│                                                      │'
  '│   Written by Tiran Dagan  ·  tiran@tirandagan.com    │'
  '│   Copyright © 2026 Tiran Dagan                       │'
  '│                                                      │'
  '╰──────────────────────────────────────────────────────╯'
)
msg=""
for l in "${lines[@]}"; do msg="$msg\\n$l"; done
printf '{"systemMessage": "%s\\n"}\n' "$msg"
