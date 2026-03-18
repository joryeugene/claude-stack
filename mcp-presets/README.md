# MCP Presets

Drop context-specific MCP servers into any project with one command.

```zsh
mcp-use <preset>            # copy single preset -> .mcp.json
mcp-use <preset> <preset>   # merge multiple presets -> .mcp.json
mcp-use                     # list all presets
```

Restart Claude Code after running to pick up the new `.mcp.json`.

---

## What do I use?

| I need to... | Use |
|---|---|
| Run E2E tests, automate a browser | `playwright` |
| Inspect network, console, DOM in Chrome | `chrome` |
| Full browser automation + devtools | `browser` |
| Read/write Google Docs, review an RFC | `workspace` |
| Check Google Calendar or Sheets | `workspace` |
| Build React components with shadcn/ui | `shad` |
| Visually verify a component against a design | `ui` |
| Full stack session (tests + docs + UI) | `all` |

---

## Presets

### `playwright`
Playwright MCP for writing and running E2E tests, form filling, and browser automation.

```zsh
mcp-use playwright
```

### `chrome`
Chrome DevTools MCP for network inspection, console monitoring, and DOM debugging.

```zsh
mcp-use chrome
```

### `browser`
playwright + chrome-devtools

Full browser session: automate flows with Playwright, inspect internals with DevTools.

```zsh
mcp-use browser
```

### `workspace`
Google Docs, Drive, Calendar, Sheets

Read and write Google Workspace documents. Good for RFC review, drafting docs, checking meetings.

Requires OAuth on first use. Run workspace-mcp standalone once to authenticate.

```zsh
mcp-use workspace
```

### `shad`
shadcn-ui component library. Search components, get usage examples and installation commands.

```zsh
mcp-use shad
```

### `ui`
shadcn-ui + chrome-devtools

Search shadcn component library, get usage examples, then visually verify the result in a real browser.

```zsh
mcp-use ui
```

### `all`
Everything above.

```zsh
mcp-use all
```

---

## Combine presets

```zsh
mcp-use workspace browser    # RFC review + browser verification
mcp-use workspace playwright # docs + E2E tests
```

---

## Always-on (global, no preset needed)

- **hive** - knowledge memory, always loaded
- **gitmcp** - library docs lookup, always loaded
- **context7** - library docs via plugin, always loaded
