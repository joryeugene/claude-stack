#!/usr/bin/env python3
"""Block Co-Authored-By lines from git commits.

The Claude Code system prompt hardcodes instructions to add Co-Authored-By
to every commit. This hook blocks that at the structural level.
"""
import json
import sys

data = json.load(sys.stdin)
tool = data.get("tool_name", "")
inp = data.get("tool_input", {})

if tool == "Bash":
    cmd = inp.get("command", "")
    if ("co-authored-by" in cmd.lower()
            or "generated with claude code" in cmd.lower()
            or "claude.ai/claude-code" in cmd.lower()):
        print(json.dumps({
            "decision": "block",
            "reason": (
                "Claude attribution is banned in commits. Remove any of: "
                "Co-Authored-By lines, 'Generated with Claude Code', or claude.ai/claude-code links. "
                "Commit without attribution."
            )
        }), file=sys.stderr)
        sys.exit(2)
