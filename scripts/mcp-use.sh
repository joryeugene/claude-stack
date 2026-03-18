#!/usr/bin/env bash
# Copy or merge MCP server presets into .mcp.json in the current directory.
#
# Usage:
#   mcp-use                      -> list available presets
#   mcp-use playwright           -> playwright MCP only
#   mcp-use chrome               -> chrome-devtools MCP only
#   mcp-use browser              -> playwright + chrome-devtools
#   mcp-use shad                 -> shadcn-ui only
#   mcp-use ui                   -> shadcn-ui + chrome-devtools
#   mcp-use workspace            -> Google Workspace
#   mcp-use best                 -> gitmcp + hive (foundation)
#   mcp-use all                  -> everything
#   mcp-use browser workspace    -> merge multiple presets
#
# Presets live in ~/.config/mcp-presets/
#
# To install as a shell function, add to your ~/.zshrc or ~/.bashrc:
#   source ~/.claude/skills/claude-stack/scripts/mcp-use.sh
#
# Or invoke directly:
#   bash ~/.claude/skills/claude-stack/scripts/mcp-use.sh browser

PRESET_DIR="${MCP_PRESET_DIR:-$HOME/.config/mcp-presets}"

mcp-use() {
  if [[ $# -eq 0 ]]; then
    echo "Available presets:"
    for f in "$PRESET_DIR"/*.json; do
      [[ -f "$f" ]] || continue
      echo "  $(basename "$f" .json)"
    done
    return
  fi

  # Validate all presets exist before touching .mcp.json
  for name in "$@"; do
    if [[ ! -f "$PRESET_DIR/$name.json" ]]; then
      echo "Unknown preset: $name (available: $(ls "$PRESET_DIR"/*.json 2>/dev/null | xargs -n1 basename | sed 's/\.json//' | tr '\n' ' '))" >&2
      return 1
    fi
  done

  if [[ $# -eq 1 ]]; then
    cp "$PRESET_DIR/$1.json" .mcp.json
    echo ".mcp.json <- $1"
    return
  fi

  python3 - "$@" <<'PYEOF'
import json, sys, os
preset_dir = os.environ.get("MCP_PRESET_DIR", os.path.expanduser("~/.config/mcp-presets"))
result = {"mcpServers": {}}
for name in sys.argv[1:]:
    with open(os.path.join(preset_dir, name + ".json")) as f:
        result["mcpServers"].update(json.load(f).get("mcpServers", {}))
with open(".mcp.json", "w") as f:
    json.dump(result, f, indent=2)
    f.write("\n")
print(".mcp.json <- " + " + ".join(sys.argv[1:]))
PYEOF
}

# If executed directly (not sourced), run the function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] || [[ "$0" == *mcp-use.sh ]]; then
  mcp-use "$@"
fi
