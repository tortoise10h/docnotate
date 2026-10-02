# Copy All Comments Button

## Overview
Final MVP feature for persisted comments. Adds a "Copy comments" button below the existing nav up/down controls in the document view. Clicking it copies all currently-anchored comments on the document to the clipboard in a fixed format, ready to paste into an agent console as feedback on an agent plan. No server changes — all logic is client-side, in a **new dedicated Stimulus controller** so `comment_highlight_controller` keeps its single responsibility (highlighting + navigation + popover).

## Output format
```
1. "Text is selected"
> Our comment here

2. "Text is selected"
> Our another comment here
```
- 1-indexed entries, `N. "<selected_text>"` on the first line, `> <content>` on the next.
- Entries separated by exactly one blank line (`\n\n`).
- Numbering follows **document position** (top-to-bottom reading order), not `created_at`, so the user/agent reads the feedback in the same spatial order they see it on the page.

## Scope decisions
- **Client-side only.** The server has no knowledge of which anchor blocks still exist in the rendered DOM, so filtering to "currently-rendered comments" must happen in the browser. No Ruby changes.
- **New dedicated controller `comment_copy_controller.js`.** The `comment_highlight_controller` already mixes highlight-application, popover, and navigation; adding copy would push it past a comfortable size and conflate a separate concern. A focused controller is easier to read and test.
- **Self-contained: re-reads the JSON source.** The new controller parses the same `<script data-comment-highlight-target="source">` JSON that `comment_highlight_controller` reads, filters to comments whose `start_block_id` still exists in the DOM, and sorts by document position. This duplicates ~10 lines of filtering logic but fully decouples the two controllers (no cross-controller lookup, no shared event protocol, no ordering dependency).
- **No reuse of `clipboard_controller`.** That controller sets `textValue` at render time; we need the value computed at click time from current DOM state. Reusing it would require wiring a dynamic value, which is more awkward than a focused new controller.

### Existing context (relevant)
- `app/models/comment.rb` already persists `selected_text` and `content` — the two fields we format from. No schema change.
- `app/views/documents/show.html.erb:67-69` already emits the JSON payload in a `<script type="application/json" data-comment-highlight-target="source">` tag. The new controller adds its own target attribute to the same element (`data-comment-copy-target="source"`) — Stimulus targets are scoped per-controller, so the two names coexist on one element.
- `app/views/documents/show.html.erb:53-65` already hosts `.document__comment-nav` — the new button sits immediately below it inside `.document__paper`.

---

## 1. View — `app/views/documents/show.html.erb`

### Add a target to the existing JSON script tag (line 67)
The same `<script>` payload now serves both controllers:

```erb
<script type="application/json" data-comment-highlight-target="source" data-comment-copy-target="source">
  <%= @comment_payload.to_json.html_safe %>
</script>
```

### Add the copy button below `.document__comment-nav`
Immediately after line 65 (after the nav block closes), inside `.document__paper`. Only render when comments exist — avoids a useless button on commentless documents:

```erb
<% if @document.comments.exists? %>
  <button type="button" class="document__comment-copy"
          data-comment-copy-target="button"
          data-action="click->comment-copy#copyComments">
    <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="14" height="14" x="8" y="8" rx="2" ry="2"/><path d="M4 16c-1.1 0-2-.9-2-2V4a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2"/></svg>
    <span data-comment-copy-target="label">Copy comments</span>
  </button>
<% end %>
```

### Controller placement
Put `data-controller="comment-copy"` on `.document__paper` (stacked alongside `text-selection comment-highlight`), not on the button itself. The button and the JSON `<script>` source both live inside `.document__paper`, so both resolve as targets of the controller:

```erb
<div class="document__paper" data-controller="text-selection comment-highlight comment-copy">
```

---

## 2. JS — `app/javascript/controllers/comment_copy_controller.js` (new)

```js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["source", "button", "label"]

    connect() {
        this.copyTimeout = null
        this.loadComments()
    }

    disconnect() {
        if (this.copyTimeout) clearTimeout(this.copyTimeout)
    }

    loadComments() {
        let payload = []
        try {
            payload = JSON.parse(this.sourceTarget.textContent)
        } catch {
            payload = []
        }

        // Keep only comments whose start block still exists in the DOM,
        // sorted by document position (top-to-bottom reading order).
        this.orderedComments = payload
            .filter(comment => document.getElementById(comment.start_block_id))
            .sort((a, b) => {
                const elA = document.getElementById(a.start_block_id)
                const elB = document.getElementById(b.start_block_id)
                if (elA === elB) return 0
                const position = elA.compareDocumentPosition(elB)
                return position & Node.DOCUMENT_POSITION_FOLLOWING ? -1 : 1
            })

        this.buttonTarget.style.display =
            this.orderedComments.length > 0 ? "inline-flex" : "none"
    }

    async copyComments() {
        if (this.orderedComments.length === 0) return

        const text = this.orderedComments.map((comment, index) => {
            return `${index + 1}. "${comment.selected_text}"\n> ${comment.content}`
        }).join("\n\n")

        try {
            await navigator.clipboard.writeText(text)
            this.flashCopied()
        } catch (error) {
            console.error("Failed to copy comments:", error)
        }
    }

    flashCopied() {
        this.labelTarget.textContent = "Copied!"
        if (this.copyTimeout) clearTimeout(this.copyTimeout)
        this.copyTimeout = setTimeout(() => {
            this.labelTarget.textContent = "Copy comments"
        }, 2000)
    }
}
```

### Notes
- **No change to `comment_highlight_controller.js`.** The two controllers each read the same JSON source independently and maintain their own state; they don't reference each other.
- **Filtering matches the highlight controller's behavior** — a comment is included iff its `start_block_id` resolves in the current DOM. We use `start_block_id` only (not also `end_block_id`) for the existence check, mirroring `navigableComments`'s `firstMark`-presence filter (a comment's first mark exists iff its start block exists).
- Document-position sort uses `compareDocumentPosition` on the start-block elements — same technique as `buildNavigableComments` uses on the marks.
- `navigator.clipboard.writeText` can reject in non-secure contexts or when the document lacks focus; the try/catch logs and leaves the label untouched so the user notices nothing happened.
- We access `comment.selected_text` / `comment.content` directly from the parsed JSON object (ActiveSupport serializes symbol keys as snake_case strings in `to_json`), no camelCase mapping needed.
- Controller is auto-registered via `eagerLoadControllersFrom` (no importmap change needed, per the project's existing setup).

---

## 3. CSS — `app/assets/stylesheets/pages/document.css`

```css
.document__comment-copy {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-size: 0.75rem;
  color: #6b7280;
  background: none;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  padding: 4px 8px;
  cursor: pointer;
}

.document__comment-copy:hover {
  color: #1d1d1f;
  border-color: #d1d5db;
}
```

- Sized to sit visually below `.document__comment-nav`.

---

## Behavior Summary
- User adds comments on the document; persisted highlights appear as before (unchanged).
- "Copy comments" button renders below the nav controls, visible only when at least one comment is currently anchored in the DOM.
- Click → all currently-anchored comments are formatted in document order and written to the clipboard; the label flashes "Copied!" for 2s.
- User pastes into the agent console as feedback; the format matches the requested spec exactly.

## Verification
Manual, via `bin/rails dev`:

1. Add 2+ comments (single-block and multi-block) on a document → click "Copy comments" → paste into a plain text editor → confirm format matches the spec and ordering is top-to-bottom in the document.
2. Document with zero comments → button not present.
3. Document where one comment's `start_block_id` no longer exists in the DOM (e.g. after editing the source file and reloading) → that comment is excluded from the copied output; button hides if no comments remain anchored.
4. Click the button when the page lacks focus (e.g. DevTools focused) → on browsers that reject the clipboard write, label stays "Copy comments" and an error logs to the console; no crash.
5. After clicking, the label reverts to "Copy comments" after 2s.
6. Confirm the highlight+nav+popover behavior is unchanged (the `comment_highlight_controller` was not modified).

## Edge cases handled
- Multi-line `selected_text` or `content` → newlines preserved verbatim in the clipboard output (matches the user's intent; the agent console reads raw text).
- Inner quotes in `selected_text` → left as-is; the surrounding `"..."` are literal, no escaping (matches the requested format which shows raw quoted text).
- Empty `orderedComments` at click time → action bails silently, no clipboard write, label unchanged.
- Three stacked controllers on `.document__paper` (`text-selection`, `comment-highlight`, `comment-copy`) coexist without target conflicts — each namespace is independent.
- `disconnect()` clears the success timeout so no stale callback fires after a Turbo navigation.