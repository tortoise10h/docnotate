# Render Mermaid diagrams in documents

## Goal
When a fenced code block in a document is tagged `mermaid` (e.g. ` ```mermaid `), render it as an SVG diagram in the document view instead of plain code text — with a graceful fallback to raw code when rendering fails.

## Context
- Markdown is parsed with **commonmarker (~> 2.8)** in `app/models/markdown_parser.rb` into node rows stored in `document_nodes`, then re-rendered as HTML by the recursive partial `app/views/documents/_document_node.html.erb`.
- Code blocks already carry their fence language: `meta = {"language" => node.fence_info}` (`app/models/markdown_parser.rb` line ~72), and `_document_node.html.erb` emits `<code class="language-<lang>">`. So a mermaid block is already identifiable in the DOM — **no parser/model changes needed**.
- JS stack is **importmap-rails + propshaft + Stimulus/Turbo**; no bundler, no package.json. `config/importmap.rb` pins turbo/stimulus; vendor pins live in `vendor/javascript/`.
- The document content container (`div.document__paper` in `app/views/documents/show.html.erb`) already carries the controller stack `text-selection comment-highlight comment-copy comment-popover`. Comment highlighting (`text_selection_controller.js`, `comment_highlight_controller.js`) mutates text nodes inside `document__content`.
- No server-side sanitization of rendered content; everything is ERB-escaped per node. Client-side SVG rendering bypasses any server escaping concern.

## Decisions (confirmed with user)
- **Comments tradeoff accepted:** rendered mermaid blocks lose text-selection/comment ability on that block. Other blocks keep full comment support.
- **Failure fallback:** on mermaid parse/render error, restore/keep the original raw code block (optionally with a small inline error notice).
- **Delivery:** mermaid library pinned into the importmap (`bin/importmap pin mermaid`) — self-hosted, works offline.

## Plan
1. **Pin mermaid in the importmap**
   - Run `bin/importmap pin mermaid` to vendor it into `vendor/javascript/` and record the pin in `config/importmap.rb`.
2. **Add a `mermaid` Stimulus controller** — `app/javascript/controllers/mermaid_controller.js`
   - Attach once on the content container in `app/views/documents/show.html.erb`: add `mermaid` to the existing `data-controller` list on `div.document__paper`, with `data-mermaid-target="container"` (or query within `document__content`).
   - On `connect()` (and re-run on `turbo:load` semantics since Stimulus reconnect handles Turbo visits):
     - Find all `code.language-mermaid` elements inside the container.
     - For each, capture the raw source text, build a placeholder `<div class="mermaid-render">` before/instead of the `<pre>`, call `mermaid.render(unique-id, source)`.
     - On success: insert the returned SVG into the placeholder and hide/remove the original `<pre><code>` (keep the source stored, e.g. in a data attribute or by keeping the `pre` hidden, so toggling back is trivial).
     - On error: leave the `<pre><code>` untouched (optionally add a subtle "invalid mermaid" CSS class for a small notice). Log to console for debugging.
   - Initialize mermaid once (`mermaid.initialize({ startOnLoad: false, theme: ... })`) at module top, not per-connect.
   - Keep the original `<pre>` in the `node_id`-tagged state expected by the comment system where possible (hide with CSS rather than delete) to avoid touching `comment-highlight` anchors.
3. **CSS** — `app/assets/stylesheets/pages/document.css`
   - `.mermaid-render` / `.document-node--mermaid` styles: center the SVG, constrain max-width to the paper area, allow horizontal scroll for wide diagrams.
   - Optional small error-notice style used when parse fails.
4. **Tests** (minimal, matching project style)
   - `test/models/markdown_parser_test.rb`: a ` ```mermaid ` fence yields a `code_block` node with `meta["language"] == "mermaid"`.
   - Optionally extend `test/integration/documents_test.rb` to assert `language-mermaid` markup is emitted for such content. (No JS-level tests — project has no JS test setup.)

## Risks / Open questions
- **Mermaid bundle size via importmap:** mermaid is large (~1MB+ minified). Eager import may slow first load; if problematic, use a dynamic `import("mermaid")` inside the controller on connect (importmap supports dynamic imports).
- **Interaction with comment controllers:** `text_selection`/`comment_highlight` walk text nodes; a rendered SVG has none, so they should no-op on it — but if a user has existing comments anchored inside a mermaid block's text, hidden blocks may make those comment highlights invisible. Widely acceptable given the confirmed tradeoff.
- **Mermaid async timing:** `mermaid.render` is async; if multiple blocks or rapid Turbo navigations, use unique IDs per render and guard against double-connect (Stimulus `connect()` can fire again on reattach — check for already-rendered marks).
- **Version pinning:** `bin/importmap pin mermaid` grabs latest (v11+); API (`mermaid.initialize` / `mermaid.render`) is stable there, but verify after pinning.
