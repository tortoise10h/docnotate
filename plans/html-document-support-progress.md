# HTML document support — handover

Read this first, then `plans/html-document-support.md`. Its "Implementation notes" section is binding.

## Status

- **Phases 1, 2 and 3 are implemented and verified, and every item in the plan is done** except the commits and the optional reconnect affordance (see the plan's "Status and deviations" section).
- Suite: `bin/rails test` → **55 runs, 0 failures**. `bin/rails test:system` → **1 run, 0 failures**.
- Browser checks: `/tmp/cdp/phase3.mjs` → 18/18. `/tmp/cdp/copy.mjs` → 2/2 (copy writes both comments in order, button shows "Copied!").
- Nothing is committed. The working tree on `main` is uncommitted.

## Next steps

1. **Commit**, if the user asks. The plan wants one commit per phase with the suite green after each (see "Commit plan"). Don't commit `.opencode/`.
2. **Ask the user about feedback item 3.** It came through blank twice. Don't act on it until they resend it.
3. **Optional:** the reconnect affordance from the plan's failure-modes section. It is not built.

Tests added in this round:
- `test/models/documents/file_typeable_test.rb` (extension mapping and `supported_file?`).
- `test/models/html_parser_test.rb`: reparse of the same source gives the same structure and only its own ids.
- `test/integration/html_documents_test.rb`: stored `annotated_html` matches the nodes; an unchanged reopen keeps the version; a changed file creates a new version with replaced nodes.
- `test/system/html_documents_test.rb` with `test/application_system_test_case.rb` (Selenium headless Chrome): the iframe shows the file's text and the TOC lists its headings.

## Decisions (agreed with advisor 01a12445, owner of the plan)

- Block anchors are the DOM attribute `data-docnotate-block="block-<hex4>"`, not `id`. Author ids and `#fragment` links are never overwritten.
- Anchors stored in `comments` and `document_nodes.node_id` are the same `block-…` strings. Nothing on the Rails side changes for anchors.
- The parser is `Nokogiri::HTML5`. `gem "nokogiri"` is explicit in the Gemfile.
- Block rule: the plan's tag list, or an element with a direct non-whitespace text child that isn't inline. Inline tags are blocks only when no block ancestor exists. Skipped subtrees: `script style noscript template svg math`. (`svg` and `math` were added by us.)
- Node types: h1–h6 → `heading` with `heading_level`. Other blocks use the tag name. The TOC shows levels 1–3 only, like markdown.
- The frame owns the marks. The parent owns all UI and state. The bridge is the only writer to the frame.
- postMessage uses `targetOrigin "*"` in both directions (the frame's origin is opaque). The parent checks `event.source === iframe.contentWindow`, `event.origin === "null"`, and the `docnotate:` prefix. Anything else is dropped.
- Copy: the selection-copy button uses `selectedText` from the form. "Copy comments" is parent-only. The bridge never carries copy text.
- The archived list is not inside the file's layout. Rejected alternatives:
  - *Archived list below the file:* it squeezed the viewer. We changed to the toggle below.
  - *Archived list at the end of the file, rendered in the frame:* the sandbox blocks forms and same-origin access, so the resolve buttons would not work there.

## Files

**Rails / models**
- `app/models/documents/file_typeable.rb`: `html` in `FILE_TYPES`, `HTML_EXTENSIONS`, `supported_file?`, `html_file?`. `markdown_file?` kept.
- `db/migrate/20261010060528_add_annotated_html_to_document_versions.rb` and `db/schema.rb`: `document_versions.annotated_html` (text, nullable).
- `app/models/html_parser.rb`: `HtmlParser.new(document_version_id:, content:).parse` returns node attribute hashes (same shape as `MarkdownParser`). `#annotated_html` is set during the parse.
- `app/models/documents/ast_parseable.rb`: picks the parser by `html?`. For HTML it saves `annotated_html` in the same transaction. It is written only inside the parse branch, so an unchanged file doesn't create a version.
- `app/models/html_frame_document.rb`: PORO. Inlines `utils/text_anchors.js` and `html_frame/client.js` as one `<script type="module">` before `</body>` at serve time. Not stored in the DB.
- `Gemfile` / `Gemfile.lock`: `gem "nokogiri"` explicit.

**Controllers / routes / views**
- `app/controllers/documents_controller.rb`: `open` uses `supported_file?`. `DocumentContentsController#show` renders `HtmlFrameDocument` with `layout: false` for HTML content, or 404; `#asset` serves sibling files.
- `config/routes.rb`: `get "content"` and `get "content/*path"` nested under documents.
- `app/views/documents/show.html.erb`: branches on `html?` to `_html_paper` or `_markdown_paper`. Passes `html:` to the TOC partial. Sets `content_for :body_class` for HTML.
- `app/views/documents/_html_paper.html.erb`: the whole HTML page. Tabs are gone. It has the iframe in `.html-viewer`, a `.html-archived-panel` for the archived list (`hidden` by default), and the shared partials.
- `app/views/documents/_markdown_paper.html.erb`: the markdown page. It now renders `_comment_nav` and `_selection_form`. Its markup is otherwise unchanged.
- `app/views/documents/_comment_nav.html.erb` (new, shared): the nav, copy button, and inbox button. Takes a `show_inbox` local. Markdown passes `archived.any?`; HTML passes `true`. The inbox button has two icons (inbox and document), and CSS shows the one that matches `aria-pressed`.
- `app/views/documents/_selection_form.html.erb` (new, shared): hidden fields, Add Note toolbar, copy button, comment card.
- `app/views/documents/_table_of_contents.html.erb`: takes an `html` local. It sets `data-table-of-contents-html-value`, and for HTML it adds the `iframe-bridge:headings@window` action.
- `app/views/documents/unsupported_file.html.erb`: lists the new types.
- `app/views/layouts/application.html.erb`: `<body class="<%= yield(:body_class) %>">`.

**JavaScript**
- `app/javascript/utils/text_anchors.js` (new): shared anchor helpers. The frame gets a copy of this file inlined at serve time.
- `app/javascript/html_frame/client.js` (new, runs inside the frame, no imports): selection marks, `applyComments` (a port of markdown's `applyComment`, with the nested double-mark quirk kept), focus, `scrollTo`, `markClick`, `markRect`, `headings`, ready/ack, and the selection messages.
- `app/javascript/controllers/iframe_bridge_controller.js` (new, parent): validates incoming messages, buffers outgoing ones until ready (`applyComments` and `focusComment` keep only the latest), and translates rects into paper and viewport coordinates. It reads `#comment_payload_source` itself. It dispatches `iframe-bridge:*` events.
- `app/javascript/controllers/document_view_controller.js` (new): toggles the archived panel. Also swaps the inbox button's tooltip, aria-label, and `aria-pressed`.
- `app/javascript/controllers/text_selection_controller.js`: uses the shared helpers. New `showFromFrame`, `moveFromFrame`, and a `text-selection:hidden` event. Rewritten with 4-space indentation, so review with `git diff -w`.
- `app/javascript/controllers/comment_highlight_controller.js`: new `remote` value. In remote mode it skips DOM marks and reacts to `receiveMarks`. It also has `openFromFrame`, `openComment`, `scrollToComment`, and a remote branch in `scrollToArchived`. The markdown paths are unchanged.
- `app/javascript/controllers/comment_copy_controller.js`: `remote` value. Orders comments by the frame's anchor list (`receiveAnchors`).
- `app/javascript/controllers/comment_popover_controller.js`: `show` and `reposition` take a viewport rect. In remote mode it places the popover inside the viewer's right edge. `hide` now dispatches `comment-popover:closed` and clears `currentComment`.
- `app/javascript/controllers/table_of_contents_controller.js`: `html` value. In HTML mode, `updateFromFrame` picks the last TOC heading whose top is at or above the frame's top edge (threshold from the bridge). `select` dispatches `table-of-contents:navigate` in HTML mode.

**CSS** (`app/assets/stylesheets/pages/document.css`)
- `.document--wide`, `.html-document-page`, `.document__paper--html`, `.html-viewer`, `.html-viewer__frame`: the full-height HTML page.
- `.html-archived-panel`: the archived list, scrollable, shown instead of the viewer.
- `.html-document-page .document__toc-toggle`: moved into the page margin.
- `.document__comment-inbox-button[aria-pressed="true"]` and the icon switching rules.

**Tests**
- `test/models/html_parser_test.rb` (3 tests).
- `test/models/html_frame_document_test.rb` (2 tests).
- `test/integration/html_documents_test.rb` (4 tests): open renders the iframe and TOC; the content endpoint serves the annotated HTML; `.pdf` is rejected; the HTML page is wired to the bridge, the TOC, and `#previous-comments`.

## Phase 3 behavior

- Highlights are applied inside the frame on ready, and again after every create, edit, or delete (`comment-highlight:reload` → bridge pushes the payload).
- Nav next/previous follow document order and wrap. Each step scrolls the frame and moves the popover.
- A click on a highlight opens the popover. The popover follows the mark on frame scroll and hides when the mark is off-screen. It stays closed after the user closes it.
- The TOC scrolls the frame. The active TOC link follows the frame's scroll position.
- The inbox button toggles between the file and the archived list. It shows a document icon and "Back to document" while the list is open. The file view keeps the full paper height.

## Known limits (accepted, or to review)

- Relative assets (`<img src="diagram.png">`, sibling CSS) resolve through `/documents/:id/content/*path`, limited to an asset allowlist inside the document's directory. Web fonts may still fail without CORS.
- The parser doesn't annotate a `<div>` whose only child is an inline element with no direct text (e.g. `<div><span>…</span></div>`). The text can't be commented on.
- In a `<div>` that mixes direct text with child blocks, the direct text is dropped from the node. Content is nil when child blocks exist.
- The open TOC panel overlays the left edge of the frame. It closes on Escape or the close button.
- The markdown popover overlaps the fixed nav at about 1400px. This was already there, and the markdown formula is unchanged.
- The inbox button always shows on HTML files, even with no archived comments. Markdown still shows it only when archived comments exist.
- The bridge passes plain objects, so the plan's `JSON.parse`-in-try step doesn't apply.
- The iframe ready-retry gives up after 40 attempts (about 10 s). After that, selections still reach the parent, but highlights only apply once the frame acks.
- Phase 3 `phase3.mjs` cleans up its own test comments. If the script crashes midway, run the cleanup below.

## Process notes

**Tests:** `bin/rails test`. The VIPS warning on stderr is harmless.

**App server:** `bin/rails server -p 3999 -P /tmp/docnotate.pid`. Open `http://localhost:3999/documents/open?file_path=/absolute/path.html`. Stop with `kill $(cat /tmp/docnotate.pid)`. Check it's running with `curl -s -o /dev/null -w "%{http_code}" http://localhost:3999/`.

**Chrome for the browser checks** (needed by the harness):
```
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --disable-gpu --no-sandbox --remote-debugging-port=9222 --user-data-dir=/tmp/chrome-cdp --window-size=1400,900 about:blank &
```

**Browser harness** (`/tmp/cdp/`, outside the repo; it may be gone):
- `lib.mjs` is the CDP helper. It attaches to the frame as its own `iframe` target, since the sandboxed frame is out-of-process. It disables the cache, because Chrome kept serving an old stylesheet otherwise.
- `phase3.mjs` is the Phase 3 scenario. It needs `/tmp/style-guide.html` and `/tmp/sample-md.md`, and it creates `/tmp/phase3-archive.html`. Run it with `cd /tmp/cdp && node phase3.mjs`.
- `copy.mjs` is the copy-comments check. It stubs `navigator.clipboard.writeText` and deletes its own comments.
- `e2e.mjs` is the older Phase 2 script. It still runs, but `phase3.mjs` covers the same flows.
- If the harness is gone, rebuild it from `lib.mjs`'s approach above.

**Cleanup after a crashed run** (test comments in the dev DB):
```
bin/rails runner 'Comment.where(content: ["First note","Second note","Second note edited","Archive me","Markdown note","Copy note one","Copy note two"]).destroy_all'
```

**Dev DB:** sample documents (`style-guide.html`, `phase3-archive.html`, `sample-md.md`) and their versions remain. Nothing else needs cleaning up.

**Screenshots:** `"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --disable-gpu --no-sandbox --window-size=1400,900 --screenshot=/tmp/x.png "<url>"`. `timeout` isn't available on this macOS.

## Commit plan

The plan asks for one commit per phase, suite green after each:
1. Phase 1: file type, parser, migration, render, and the Phase 1 tests.
2. Phase 2: the bridge, the frame client, the shared helpers, `_selection_form`, and the Phase 2 tests.
3. Phase 3: the remaining JS and views, the nav partial, and the Phase 3 tests.

The phases share files (`_html_paper`, `document.css`, `text_selection_controller.js`), so split them with `git add -p`. Don't commit `.opencode/`.

## Advisor

Intercom ID `01a12445` (`docnotate-html-support-advisor`). Ask it about design questions. Use `ask` with the session ID if the name doesn't resolve.
