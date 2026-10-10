# HTML document support (render `.html`/`.htm` files with full annotation parity)

## Goal

Let DocNotate open agent-generated HTML files through the same flow as markdown, so the existing
inline-comment / highlight / TOC / versioning features work on them — while the HTML keeps its own
CSS and JS inside a sandboxed iframe, preserving the "free UI" advantage that motivated the format.

## Confirmed decisions

1. **Rendering: sandboxed iframe.** The file's own styles render untouched; no CSS scoping hacks.
   HTML documents also get a **wider canvas**: the page container `.document` is currently capped at
   `max-width: 900px` (`app/assets/stylesheets/pages/document.css:575`) — good for reading prose,
   too narrow for dashboards/visualizations. For HTML files, `show.html.erb` adds a BEM modifier
   (e.g. `document--wide`) that raises the container to `~90vw` so the iframe paper uses most of
   the viewport. Markdown keeps the existing 900px reading width unchanged.
2. **Scripts: allowed**, inside the iframe sandbox only. We generate these files ourselves, so we
   accept the trust tradeoff; the sandbox still blocks top-navigation, forms, and same-origin
   access to the app.
3. **Scope: full parity** — selection comments, persistent highlights, comment nav/copy, TOC,
   archived comments across versions.
4. **Entry point: unchanged** — `/documents/open?file_path=...` accepts `.html`/`.htm`.

## Context (what exists today)

- `DocumentsController#open` rejects non-markdown files via `Document.markdown_file?`
  (`app/controllers/documents_controller.rb`, `app/views/documents/unsupported_file.html.erb`).
- `Documents::FileTypeable` (`app/models/documents/file_typeable.rb`) holds `FILE_TYPES`
  (`markdown text pdf` — `pdf` is already declared but unreachable) and the extension→type map.
- `Documents::FileSyncable#open` (`app/models/documents/file_syncable.rb`) is file-type agnostic:
  mtime/size staleness detection, `DocumentVersion` creation via
  `Documents::AstParseable#parse_ast_and_save!`.
- `AstParseable#parse_ast_and_save!` hardcodes `MarkdownParser` (`app/models/markdown_parser.rb`,
  Commonmarker) to build the `DocumentNode` tree. Block-level nodes get random
  `node_id`s (`block-...`) at parse time — ids are per-version, comments anchor to them.
- Rendering is DOM-driven from server-rendered AST (`app/views/documents/_document_node.html.erb`).
  The whole annotation stack keys off `[id^="block-"]` inside `.document__content`
  (`app/javascript/utils/dom_selectors.js`): `text_selection_controller.js` (selection → block ids
  + text offsets), `comment_highlight_controller.js` (re-applies `<mark>`s from the comment payload
  JSON, nav, archived inbox), `comment_popover_controller.js`, `selection_copy_controller.js`,
  `comment_copy_controller.js`.
- `Documents::TableOfContents` walks the node tree for `heading` nodes (levels 1–3).
- Nokogiri is already in the lockfile (via `rails-html-sanitizer`) — no new dependency.

## Core insight (why this is feasible)

The annotation stack is **not** markdown-specific — it only needs:
1. Block elements carrying `id="block-…"` in the rendered DOM.
2. A server-side `DocumentNode` tree matching those ids (for comments, versions, TOC).
3. The payload-source JSON + `.document__content` container conventions.

So the plan is: parse HTML server-side with Nokogiri into the *same* `DocumentNode` shape, inject
`block-…` ids into the HTML at parse time, render the annotated HTML inside a sandboxed iframe, and
bridge selection/highlight events across the iframe boundary with `postMessage`.

## How comments work on HTML files (the mechanism)

The guiding rule: **the iframe is a dumb viewer; the parent page owns all comment UI and state.**
The sandbox (`allow-scripts` only, no `allow-same-origin`) makes the iframe an opaque-origin
document — it cannot touch the app DOM, storage, or cookies. The only channel in either direction
is `window.parent.postMessage` / `iframe.contentWindow.postMessage`. Everything below rides on
that channel. Selector note: the markdown path uses `BLOCK_SELECTOR = '[id^="block-"]'`
(`utils/dom_selectors.js`); the in-iframe client uses its own selector
`[data-docnotate-block]`. Anchor values are the same `block-…` strings in both paths.

### The two participants

- **In-iframe client** — a small vanilla script served into the iframe. No Stimulus, no imports
  (opaque origin can't load the app's importmap). It does only DOM-local work: observe selections,
  compute anchors, wrap text in `<mark>`, report geometry. It is **injected at serve time** by the
  `html_render` action (appended before `</body>`), not stored in `annotated_html` — so client
  script fixes/improvements apply to already-parsed versions without reparse, and the stored
  column stays a pure id-annotated copy of the file.
- **`iframe_bridge` controller (parent)** — one new Stimulus controller on the iframe wrapper.
  It validates `event.source === iframe.contentWindow` and a `docnotate:` message-type prefix,
  then either feeds events into the *existing* controllers (`text-selection`,
  `comment-highlight`, `comment-popover`) or relays their commands down into the iframe.

### Message protocol (one shape, typed)

```js
// iframe → parent
{ type: "docnotate:selection",  blockIds, startOffset, endOffset,
  selectedText, prefixText, postfixText,
  rects: [{left, top, right, bottom}] }      // iframe-relative
{ type: "docnotate:markClick", commentId, rect: {...} }

// parent → iframe
{ type: "docnotate:applyComments", comments: [...] }   // same payload as markdown
{ type: "docnotate:scrollTo", commentId }
{ type: "docnotate:clearSelection" }
```

### Lifecycle of a comment

1. **User selects text inside the iframe.** The in-iframe client runs the *same* anchor math as
   the markdown path (leaf-block filtering, per-block text offsets — extracted into a shared
   helper and embedded into the client at parse time), then posts `docnotate:selection` with the
   anchors plus the selection's client rects, which are **iframe-relative**.
2. **Parent shows the existing "Add Note" toolbar.** `iframe_bridge` translates the rects by the
   iframe's own `getBoundingClientRect()` offset, then drives the same toolbar/comment-card flow
   `text_selection_controller.js` already implements — the hidden fields and submission path are
   unchanged.
3. **Comment is created as today.** `comments#create` stores
   `{start_block_id, end_block_id, start_offset, end_offset, selected_text, document_version_id}`
   — identical schema, because step 1 produced the same anchor format against the same
   `document_nodes` rows the server parsed. Nothing about `Comment` changes.
4. **Highlight application (on load and after every change).** The parent already serializes the
   comment payload into the page (`comments/_payload_source.html.erb`). `iframe_bridge` pushes it
   into the iframe as `docnotate:applyComments`; the client clears its old marks and re-applies
   `<mark>` spans by walking each comment's start/end block elements and slicing text nodes at
   the stored offsets — the same restoration algorithm
   `comment_highlight_controller.js` uses, just executing inside the iframe's DOM.
5. **Interacting with a highlight.** Clicking a `<mark>` inside the iframe posts
   `docnotate:markClick` with the comment id and the mark's rect; the parent opens the existing
   comment popover (`comments/_popover.html.erb`), position-translated like the toolbar.
6. **Navigation & scroll.** Comment nav / TOC links must scroll *within* the iframe (the iframe
   document has its own scrollbar and never scrolls the parent). The parent sends
   `docnotate:scrollTo`; the client does `blockEl.scrollIntoView()` and can flash the mark.
7. **Resolve / edit / delete.** All go through the existing Turbo Stream endpoints untouched;
   after a successful mutation the parent broadcasts a fresh `docnotate:applyComments` so the
   iframe re-renders its marks. Archived (previous-version) comments stay in the parent-only
   inbox, exactly like markdown — the client only ever receives `payload.current` for marking.

### Failure modes this design avoids

- No styling leakage either way: app CSS can't break the file's UI, file CSS can't break the app.
- A script crash inside the iframe never kills the app page; the parent UI degrades to
  "read-only view" and `iframe_bridge` can surface a reconnect affordance.
- The markdown path keeps working unchanged: the bridge is inert unless `@document.html?`.

## Plan

### Phase 1 — File type + parse + static render + TOC (no comments)

1. **`Documents::FileTypeable`**: add `"html"` to `FILE_TYPES`, add
   `HTML_EXTENSIONS = %w[.html .htm]`, handle it in `file_type_from_path`, and generalize
   `markdown_file?` → `supported_file?` (keep `markdown_file?` delegating for any other callers).
2. **Migration: add `annotated_html` (text, nullable) to `document_versions`.** What this is for,
   concretely:

   - **Why ids must exist in the HTML.** A comment stores `start_block_id` / `end_block_id`
     pointing at block anchors like `data-docnotate-block="block-abc123"`. For markdown this
     works because the ERB renderer reads the ids from the stored `document_nodes` and paints
     them onto the DOM. For HTML there is no renderer that rebuilds the DOM — the browser renders
     the file as-is — so the anchors must already be **inside the HTML itself** when it lands in
     the iframe, and they must match the ids stored in `document_nodes` for that version.
   - **Why we can't inject them at render time.** Block ids are generated randomly
     (`"block-" + SecureRandom.hex(4)`, same format as `MarkdownParser#unique_block_id`, with a
     per-version uniqueness re-draw on collision) at parse time. If we re-parsed the file at
     render time to inject anchors, we'd generate *different* random ids than the parse stored,
     and every highlight/comment would desync from its anchor. So the id-annotated serialization
     is produced **once, at parse time, in the same transaction** as the node rows, and stored on
     the version.
   - **What happens on render.** `GET /documents/:id/html_render` simply streams
     `current_version.annotated_html` into the iframe — no parsing, no re-walking, guaranteed
     consistent with the comment anchors. Markdown versions leave the column `NULL` (it's
     type-agnostic, so a future format can reuse it).
   - **Storage cost** is roughly one extra copy of the file per version (acceptable for plans and
     explainers; these are kilobytes, not megabytes).

   *Alternative considered:* make block ids **deterministic** (derived from the element's stable
   path in the document instead of `SecureRandom`) so ids can be recomputed identically at render
   time and the column disappears entirely. It's a viable simplification, but it changes id
   semantics for the whole system (and markdown's parser with it), so this plan keeps the stored
   column as the lower-risk option.
3. **`HtmlParser`** (`app/models/html_parser.rb`, sibling of `MarkdownParser`):
   - Parse content with `Nokogiri::HTML5` (gumbo, browser-like parsing — these files are consumed
     by browsers, so the browser is the reference implementation).
   - Walk **block-level elements** and annotate them with `data-docnotate-block="block-<hex4>"`
     (attribute, not `id` — user-supplied ids, `getElementById`, and `#fragment` links in the file
     stay intact). An element is a block if it is in the tag list (`p, h1..h6, li, blockquote,
     pre, table, hr, img, td/th, section, dd, figcaption, main, nav, aside, article, header,
     footer, figure, dl, dt, ul, ol, div`) **or** it has a direct non-whitespace text child and is
     not an inline element (exclude `span, a, strong, em, b, i, code, u, small, sup, sub, mark,
     abbr, …`). Skip `script, style, noscript, template, head`. Nested blocks are fine — the
     leaf-block filtering in the selection logic already handles nesting.
   - Extract headings (h1–h6) into `heading` nodes with `heading_level` and text content (TOC
     displays levels 1–3 only, same as markdown).
   - Build `DocumentNode` rows: heading nodes for h1–h6, other blocks use the tag name as
     `node_type`. Non-block elements are not node rows — comments anchor at block granularity
     like markdown.
   - Serialize with HTML5 serialization and store as the version's `annotated_html`.
4. **Parser selection**: in `Documents::AstParseable#parse_ast_and_save!`, branch on `file_type`
   (`MarkdownParser` vs `HtmlParser`); for HTML, persist `annotated_html` on the new version in the
   same transaction.
5. **Controller + views**:
   - `DocumentsController#open`: replace the `markdown_file?` guard with `supported_file?`.
   - `show.html.erb` / `prepare_document`: branch on `@document.html?` → render a new
     `documents/html_viewer` partial instead of the node-tree loop, and add the `document--wide`
     modifier class to the page container (~90vw paper, see Confirmed decisions).
   - `html_viewer` partial: `<iframe sandbox="allow-scripts" src="/documents/:id/html_render">`
     wrapped in a Stimulus `iframe_bridge` controller (phase 2 fills the bridge in).
   - New route + controller action `GET /documents/:id/html_render` streaming
     `current_version.annotated_html` with `content_security_policy` left to the sandbox.
   - Update `unsupported_file.html.erb` message to reflect the new supported list.

**Phase 1 exit criteria**: open an `.html` file, see it rendered with its own styles inside the
iframe, TOC sidebar populated from its headings, file edits picked up as new versions.

### Phase 2 — Selection → create comment (bridge out)

6. **Shared anchor helpers**: extract offset/block-id computation from
   `text_selection_controller.js` into `app/javascript/utils/text_anchors.js` so the iframe-side
   client and the parent controllers use one implementation (see the mechanism section above).
7. **In-iframe client**: a small vanilla JS file (e.g.
   `app/javascript/docnotate_iframe_client.js` kept as a static string source, or served from
   `public/`) that `html_render` appends into the response before `</body>` at serve time:
   - detects text selection and computes `{blockIds, start/end offsets, selectedText, prefix,
     postfix}` using the shared helper logic (self-contained inside the iframe — the iframe is
     opaque origin and cannot import from the app),
   - `postMessage`s the selection up to the parent,
   - receives `reply`-style messages to draw its own selection state.
8. **Parent bridge**: `iframe_bridge` controller relays iframe selection events into the existing
   `text-selection` flow (fills the same hidden fields, shows the same "Add Note" toolbar,
   positioned by translating iframe-relative rects by the iframe's offset). Built from day one
   with a **ready handshake**: the iframe posts `docnotate:ready` once connected; the parent
   buffers outgoing messages until then and flushes (prevents `applyComments` racing the iframe
   script's listener registration).

### Phase 3 — Highlights, popover, nav, copy, archived comments (bridge in)

9. Parent pushes the existing `comment_payload` JSON into the iframe; the in-iframe client applies
   persistent `<mark>` highlights using the same matching logic as
   `comment_highlight_controller.js` (offset-based range restoration).
10. Popover/comment-card positioning: iframe reports client rects; parent offsets by iframe
    position and renders the existing `comments/popover` partial as-is.
11. Comment nav, copy-comments, selection-copy, and the archived-comments inbox reuse the existing
    controllers — only the DOM-touching steps are re-pointed through the bridge.
12. Scroll-to-comment (nav + TOC) must scroll *inside* the iframe via a bridge command.

### Tests (Minitest, targeted only)

- `HtmlParser`: block-id injection, heading extraction, script preservation, idempotency on reparse.
- `FileTypeable`: extension→type mapping.
- `Documents::FileSyncable` / `AstParseable` integration: open HTML file → version + nodes +
  `annotated_html` persisted; file change → new version.
- Controller test: `open` accepts `.html`, still rejects other extensions.
- A system test for iframe render + TOC presence (Capybara/Selenium, already set up).

## Complexity answer (per your question on full parity)

Yes — still feasible, and the Rails/model side is small (Phases 1's steps 1–5). The real cost is
Phase 2–3: the annotation controllers assume same-DOM access, so we duplicate their
DOM-manipulation inside the iframe behind a `postMessage` bridge. Mitigations that keep it sane:
extract shared anchor math into one module, keep the iframe client a single self-contained script,
and keep parent controllers unchanged except for delegating DOM ops. If the bridge balloons, ship
Phases 1–2 (read + comment creation) and defer Phase 3 polish — the data model already supports
everything from day one.

## Risks / Open questions

- **Relative assets in HTML files** (e.g. `<img src="diagram.png">`, sibling CSS) won't resolve:
  the iframe is served from `/documents/:id/html_render`, not from the file's directory. Data-URIs,
  absolute URLs, and CDN links work. Serving sibling files from disk is a possible follow-up.
- **Executing file JS**: allowed by decision; the sandbox blocks top-navigation and same-origin
  access, but a malicious file could still fetch remote resources inside the frame. Accepted for
  self-generated files; a per-document "disable scripts" toggle is a cheap later addition.
- **CSP**: app CSP (if configured) must not be forced onto the iframe response; keep
  `html_render` exempt or serve permissive policy for that action only.
- **Selection edge cases**: selections spanning the iframe↔parent boundary are impossible (good),
  but multi-block selections across complex nested HTML need the same leaf-block filtering the
  markdown path uses — covered by reusing `collectBlockIds` logic.
- **`file_type = "pdf"`** is declared in `FILE_TYPES` but unreachable; leave as-is (out of scope).

## Implementation notes for the implementing agent

Read this before coding, plus the project's `AGENTS.md` — its conventions are binding here.

### Project conventions that apply to this feature

- **Models/concerns**: model-specific modules live under the pluralized namespace
  (`app/models/documents/…`, e.g. the existing `file_typeable.rb`, `ast_parseable.rb`). Keep the
  `Document` class thin — new behavior goes into a `Documents::*` concern, not the model body.
  Parsers (`MarkdownParser`, and the new `HtmlParser`) are plain POROs in `app/models/`.
- **Controllers**: 37signals style — thin actions, `before_action` for shared lookups, private
  methods at the bottom. Follow `documents_controller.rb`'s existing shape.
- **Views**: split components into partials; `show.html.erb` is already near the size limit, so
  the HTML-doc branch must live in a new partial, not inline.
- **CSS**: BEM, pure CSS. Page-scoped styles for the document screen belong in
  `app/assets/stylesheets/pages/document.css` (the `.document--wide` modifier and iframe styles
  go there); no new manifest entries.
- **JS**: Stimulus controllers are auto-registered via
  `eagerLoadControllersFrom("controllers", application)` in `controllers/index.js` — dropping a
  new `*_controller.js` file is enough, no manual registration.
- **Tests**: Minitest, targeted only. Existing patterns to copy:
  `test/models/markdown_parser_test.rb` (parser), `test/integration/documents_test.rb`
  (controller/open flow), Capybara + Selenium already configured for system tests.
- **Run tests**: `bin/rails test` (system: `bin/rails test:system`). Keep the full suite green —
  the markdown path must not regress.

### Hard-won facts about the current code (verified)

- Block ids are `"block-" + SecureRandom.hex(4)` — see `unique_block_id` in
  `app/models/markdown_parser.rb` (~line 108). Reuse the exact same format in `HtmlParser`;
  selectors and storage assume `id` starts with `block-`
  (`app/javascript/utils/dom_selectors.js` → `'[id^="block-"]'`).
- `DocumentNode` rows are created with `insert_all!` per version inside the
  `parse_ast_and_save!` transaction — mirror `AstParseable`'s flow exactly when adding the HTML
  branch; do not create nodes outside the transaction.
- The comment payload JSON is rendered by `app/views/comments/_payload_source.html.erb` and
  consumed by `comment_highlight_controller.js`; for HTML, `iframe_bridge` should read that same
  source rather than receiving a separately-rendered payload.
- `documents/show.html.erb` renders the node tree via `@root_nodes` from `prepare_document`; the
  HTML branch should skip that loop but still needs `@comment_payload`,
  `@archived_comments_by_version`, `@recent_documents`, `@editor_preference` — keep using
  `prepare_document` for both types.
- `plans/persisted-comment-highlights.md` documents how the markdown highlight pipeline works
  today — read it before touching highlight logic.

### Implementation guidance / gotchas

1. **Gemfile**: add an explicit `gem "nokogiri"` — it's currently only a transitive dependency
   (via `rails-html-sanitizer`); code should not rely on transitive deps it calls directly.
2. **`html_render` action must render with `layout: false`** and `text/html` content type, and
   must not inherit the app layout/CSP headers. If the app configures CSP, exempt this action
   (it serves file content that the sandbox isolates).
3. **Iframe attributes**: `sandbox="allow-scripts"` only. Do **not** add `allow-same-origin`
   (that would give file scripts access to the app's same-origin state) and do **not** use
   `srcdoc` (large HTML in an attribute is fragile and quoting-hazardous; a normal `src` URL is
   simpler and makes relative-URL behavior explicit).
4. **Message validation in `iframe_bridge`**: check `event.source` against the iframe and require
   the `docnotate:` type prefix; wrap `JSON.parse` in try/catch like
   `comment_highlight_controller.js` does. Never `innerHTML` anything received over the bridge —
   the parent owns UI, so it only consumes data fields (ids, offsets, text, rects).
5. **Keep `markdown_file?` working** — other call sites may exist beyond the controller guard;
   grep before renaming. Add `supported_file?` alongside rather than deleting it.
6. **Parse only on staleness**: `Documents::FileSyncable#open` reads file content every open, but
   parses only when mtime/size changed. Write `annotated_html` only inside the parse branch — an
   unchanged file re-opened must not rewrite versions.
7. **Pre-existing ids in the file**: resolved by decision — anchors use
   `data-docnotate-block` attributes, so user ids and `#fragment` links stay intact.
8. **Suggested commit sequence**: one commit per phase boundary (file-type + parser + migration
   → phase 1 render → phase 2 bridge-out → phase 3 bridge-in), suite green after each.

## Status and deviations (as built)

Status: Phases 1–3 implemented and checked. Tests: `bin/rails test` 55 runs, 0 failures;
`bin/rails test:system` 1 run, 0 failures. Browser checks (highlights, popover, nav, TOC, archived
tab, copy) pass in headless Chrome. Commits are not made yet (see item 8).

Deviations from the text above:
- Endpoints: the frame loads `GET /documents/:id/content/` (replacing `html_render`), which dispatches on the
  version's content type. Sibling files load from `GET /documents/:id/content/*path` under an asset allowlist.
- Storage: `annotated_html` is not a column on `document_versions`. It lives in an `html_contents` table, and
  `document_versions` points to its content through a polymorphic `delegated_type :content` (`content_type` /
  `content_id`). Markdown versions have no content row. Future formats (e.g. PDF) add their own content table
  without changing `document_versions`.
- The page partial is `documents/_html_paper` (the whole HTML page, including the iframe) rather than
  a separate `html_viewer` partial. Shared pieces live in `_comment_nav`, `_selection_form`, and
  `_table_of_contents`.
- The in-frame client is `app/javascript/html_frame/client.js`. `HtmlFrameDocument` inlines it, with
  `utils/text_anchors.js`, before `</body>` at serve time. This is the "injected at serve time" option.
- The bridge passes plain objects (structured clone), so no `JSON.parse` is needed.
- The archived comments are a view toggle on the nav's inbox button, not a list below the file
  (see the design note under Phase 3).
- Not built: the optional "reconnect affordance" in the failure-modes section. If the frame never acks,
  selections still reach the parent, but highlights don't apply.
- Reparse idempotency is tested as: the same source gives the same structure and only its own ids.
  The stored `annotated_html` is never reparsed, so this is the meaningful check.
