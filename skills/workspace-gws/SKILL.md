---
name: workspace-gws
description: Use the gws CLI to interact with Google Workspace APIs (Drive, Docs, Sheets, Calendar). Publish markdown specs or RFCs as Google Docs and share with recipients. Lightweight alternative to MCP-based workspace tools - no persistent server process.
---

# Google Workspace via gws CLI

`gws` is a compiled binary that wraps every Google Workspace API. No daemon, no port held, zero idle resource usage.

## Setup (one-time)

```bash
# Install
brew install googleworkspace-cli

# Authenticate (interactive OAuth flow)
gws auth setup
gws auth login
```

Credentials are stored encrypted at `~/.config/gws/credentials.enc`. Run `gws auth status` to verify.

> **Note:** `gws` requires a **Desktop app** OAuth client (not a Web app client). In GCP console: Create Credentials, OAuth client ID, Application type: **Desktop app**. Download the JSON to `~/.config/gws/client_secret.json`.

## Publish Markdown as a Google Doc

One command. Markdown headings, bold, tables, and code blocks convert to native Google Docs formatting automatically.

```bash
FILE_ID=$(gws drive files create \
  --json '{"name": "<TITLE>", "mimeType": "application/vnd.google-apps.document"}' \
  --upload ./<file>.md | jq -r '.id')

echo "https://docs.google.com/document/d/$FILE_ID/edit"
```

The `mimeType: application/vnd.google-apps.document` in `--json` triggers Drive import conversion. Without it, the file uploads as raw bytes.

### Path sandboxing (gws 0.18+)

`--upload` requires the file to be inside or below the current working directory. Absolute paths outside cwd are rejected. Either `cd` to the file's parent directory or copy the file locally first.

```bash
# From a different directory: copy first
cp /path/to/spec.md ./spec.md
gws drive files create \
  --json '{"name": "My Spec", "mimeType": "application/vnd.google-apps.document"}' \
  --upload ./spec.md
rm ./spec.md
```

### Share with recipients

```bash
# Commenter access (view + leave comments)
gws drive permissions create \
  --params "{\"fileId\": \"$FILE_ID\"}" \
  --json '{"role": "commenter", "type": "user", "emailAddress": "<EMAIL>"}'

# Anyone with the link (read-only)
gws drive permissions create \
  --params "{\"fileId\": \"$FILE_ID\"}" \
  --json '{"role": "reader", "type": "anyone"}'
```

### Get the shareable link

```bash
gws drive files get \
  --params "{\"fileId\": \"$FILE_ID\", \"fields\": \"webViewLink\"}" \
  | jq -r '.webViewLink'
```

## Reading Google Docs

### Get document content (with tabs)

```bash
gws docs documents get \
  --params '{"documentId": "<DOC_ID>", "includeTabsContent": "true"}'
```

### Fetch comments from a document

Comments are on the Drive API, not the Docs API:

```bash
gws drive comments list \
  --params '{"fileId": "<DOC_ID>", "fields": "comments(author,content,quotedFileContent,replies)", "includeDeleted": "false"}'
```

## Modifying Google Docs

### Insert text into a specific tab

```bash
gws docs documents batchUpdate \
  --params '{"documentId": "<DOC_ID>"}' \
  --json '{"requests": [{"insertText": {"location": {"index": 1, "tabId": "<TAB_ID>"}, "text": "Hello world\n"}}]}'
```

### Add a new tab to an existing document

```bash
gws docs documents batchUpdate \
  --params '{"documentId": "<DOC_ID>"}' \
  --json '{"requests": [{"addDocumentTab": {"tabProperties": {"title": "V2 (2026-03-20)", "index": 1}}}]}'
```

The new tab's ID is returned in the response under `replies[0].addDocumentTab.tabProperties.tabId`.

### Apply heading and text formatting

```bash
gws docs documents batchUpdate \
  --params '{"documentId": "<DOC_ID>"}' \
  --json '{"requests": [
    {"updateParagraphStyle": {
      "range": {"startIndex": 1, "endIndex": 30, "tabId": "<TAB_ID>"},
      "paragraphStyle": {"namedStyleType": "HEADING_1"},
      "fields": "namedStyleType"
    }},
    {"updateTextStyle": {
      "range": {"startIndex": 5, "endIndex": 15, "tabId": "<TAB_ID>"},
      "textStyle": {"bold": true},
      "fields": "bold"
    }}
  ]}'
```

Named style types: `HEADING_1` through `HEADING_6`, `NORMAL_TEXT`, `TITLE`, `SUBTITLE`.

## Command Syntax

The general pattern is `gws <service> [resource] [sub-resource] <method>`:

```bash
gws drive files list          # Drive API, files resource, list method
gws drive files create        # Drive API, files resource, create method
gws docs documents get        # Docs API, documents resource, get method
gws docs documents batchUpdate # Docs API, documents resource, batchUpdate method
gws drive comments list       # Drive API, comments resource, list method
gws drive permissions create  # Drive API, permissions resource, create method
```

Use `gws <service> --help` to see available resources. Use `gws schema <service>.<resource>.<method>` to inspect request shapes.

## Other Common Operations

```bash
# List recent Drive files
gws drive files list --params '{"pageSize": 20}' | jq '.files[] | {name, id}'

# Delete a file
gws drive files delete --params '{"fileId": "<FILE_ID>"}'

# Read a Sheets range
gws sheets spreadsheets values get \
  --params '{"spreadsheetId": "<ID>", "range": "Sheet1!A1:Z100"}'

# Write to a Sheets range
gws sheets spreadsheets values update \
  --params '{"spreadsheetId": "<ID>", "range": "Sheet1!E2", "valueInputOption": "RAW"}' \
  --json '{"values": [["<VALUE>"]]}'

# List calendar events
gws calendar events list \
  --params '{"calendarId": "primary", "maxResults": 10}' \
  | jq '.items[] | {summary, start}'
```

## Notes

- All responses are structured JSON. Pipe through `jq` for filtering.
- `gws schema <service>` introspects available methods and request shapes.
- For headless/CI use, export credentials with `gws auth export` and consume via env vars.
- Brew package name is `googleworkspace-cli` (not `gws`). Update with `brew upgrade googleworkspace-cli`.
