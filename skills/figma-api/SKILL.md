---
name: figma-api
description: Access Figma designs via the REST API using curl. Use when given a Figma URL and needing to extract design specs, node properties, or export images. Invoke with /figma-api. See also figma-extract and figma-verification for deeper extraction workflows.
---

# Figma REST API

No MCP server. Direct curl calls with FIGMA_TOKEN.

## Prerequisites

Personal access token from Figma Settings > Security > Personal access tokens.
Export as `FIGMA_TOKEN` in your shell or pass inline.

---

## URL Parsing

Every Figma design URL contains the fileKey and nodeId:

```
https://www.figma.com/design/FILE_KEY/FileName?node-id=NODE_ID
```

- `FILE_KEY`: alphanumeric string in the URL path (e.g., `AbCdEfGhIjKlMnOpQrStUv`)
- `NODE_ID`: the `node-id` query param value (e.g., `1234-5678`)
- Convert `-` to `:` in node IDs when passing to the API (e.g., `1234:5678`)

---

## Core Endpoints

### Get full file (JSON tree)
```bash
curl -s -H "X-Figma-Token: $FIGMA_TOKEN" \
  "https://api.figma.com/v1/files/FILE_KEY" \
  | jq '.document.children[0]'
```

### Get specific node
```bash
curl -s -H "X-Figma-Token: $FIGMA_TOKEN" \
  "https://api.figma.com/v1/files/FILE_KEY/nodes?ids=1234:5678" \
  | jq '.nodes["1234:5678"].document'
```

Multiple nodes: `?ids=1234:5678,9876:5432`

### Export node as SVG
```bash
curl -s -H "X-Figma-Token: $FIGMA_TOKEN" \
  "https://api.figma.com/v1/images/FILE_KEY?ids=1234:5678&format=svg&scale=2" \
  | jq '.images'
```

Returns a map of `{node_id: url}`. Fetch the URL to get the SVG content.

### Export node as PNG
```bash
curl -s -H "X-Figma-Token: $FIGMA_TOKEN" \
  "https://api.figma.com/v1/images/FILE_KEY?ids=1234:5678&format=png&scale=2" \
  | jq '.images'
```

### Get file styles (colors, text styles, effects)
```bash
curl -s -H "X-Figma-Token: $FIGMA_TOKEN" \
  "https://api.figma.com/v1/files/FILE_KEY/styles" \
  | jq '.meta.styles[] | {key, name, style_type}'
```

### Get components in a file
```bash
curl -s -H "X-Figma-Token: $FIGMA_TOKEN" \
  "https://api.figma.com/v1/files/FILE_KEY/components" \
  | jq '.meta.components[] | {key, name, description}'
```

---

## Extracting Design Specs from a Node

A frame node contains fill, stroke, size, and layout properties:

```bash
curl -s -H "X-Figma-Token: $FIGMA_TOKEN" \
  "https://api.figma.com/v1/files/FILE_KEY/nodes?ids=NODE_ID" \
  | jq '.nodes[].document | {
      name,
      type,
      size: .absoluteBoundingBox,
      fills,
      strokes,
      cornerRadius,
      layoutMode,
      paddingTop,
      paddingBottom,
      paddingLeft,
      paddingRight,
      itemSpacing
    }'
```

---

## Text Properties

```bash
curl -s -H "X-Figma-Token: $FIGMA_TOKEN" \
  "https://api.figma.com/v1/files/FILE_KEY/nodes?ids=NODE_ID" \
  | jq '.nodes[].document | .. | objects | select(.type == "TEXT") | {
      name,
      characters,
      style: .style | {fontFamily, fontWeight, fontSize, lineHeightPx, letterSpacing}
    }'
```

---

## Related Skills

- `figma-extract`: Exhaustive node extraction down to leaf nodes, cached to disk.
  Use when you need a complete offline snapshot of a Figma file.
- `figma-verification`: Verify implementation against design specs before shipping.
  Use after implementing a component to check for pixel-level discrepancies.
