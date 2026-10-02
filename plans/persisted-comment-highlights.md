# Persisted Comment Highlights

## Overview
Comment creation already works end-to-end: `text_selection_controller.js` captures block IDs + selected/prefix/postfix text, `CommentsController#create` persists the comment, and the `comments` table has `start_offset`/`end_offset` columns (currently unused). What's missing is the read side — when a document is viewed, every saved comment should be re-anchored onto the text it references as a clickable highlight, and clicking it should reveal the comment content. This requires (a) actually populating offsets at submission time, and (b) a new client-side controller that re-applies highlights on page load.

## Scope
- **Offset-based anchoring.** Compute and persist `start_offset`/`end_offset` (character offsets within the start/end block's concatenated text). Schema already supports this; no migration.
- **Multi-block highlights.** A comment spanning several blocks highlights from `start_offset` in the first block, through every intermediate block in full, to `end_offset` in the last block.
- **Floating popover** at the clicked mark showing the comment body + created date. Reuses the positioning pattern already used by the comment input card.
- **Persisted marks are distinct** from the transient `document__selection-highlight` used for the in-progress selection, so the existing `clearActiveHighlight()` (which only touches `activeMarks`) never removes them.

### Existing context (relevant)
- `app/views/documents/show.html.erb` already hosts a `data-controller="text-selection"` paper with hidden fields for `start_block_id`, `end_block_id`, `selected_text`, `prefix_text`, `postfix_text`. Missing: `start_offset` / `end_offset` fields.
- `CommentsController#create` already permits `:start_offset, :end_offset` — they're just never sent.
- `_document_node.html.erb` emits `id="block-XXXX"` on block-level nodes (from `markdown_parser.rb:90`'s `unique_block_id`) — these are the anchors.
- `text_selection_controller.js#highlightRange` already demonstrates the TreeWalker + `splitText` + `replaceChild` technique for wrapping a range in marks. We'll extract and reuse that technique.
- `CommentsController#create` redirects on success → full page reload → DOM is fresh on load, so persisted highlights apply cleanly with no conflict from any transient in-progress marks.
- No `package.json` — JS is served via importmap. New controllers under `app/javascript/controllers/` are auto-registered by `eagerLoadControllersFrom`.

---

## 1. Model — `app/models/documents/highlightable.rb` (new) + `app/models/document.rb`

Keep the shaping logic out of the view/controller and out of the thin `Comment`/`Document` AR classes (per AGENTS.md: model-specific behavior lives in a `Documents::*` concern included by `Document`). Expose it from the document side so callers say `document.highlight_comments` rather than invoking a `Comment` class method.

### New concern — `app/models/documents/highlightable.rb`
```ruby
module Documents
  module Highlightable
    extend ActiveSupport::Concern

    # Returns an array of plain Hashes (one per comment) carrying only the
    # fields the client needs to re-anchor highlights. Ordered oldest-first.
    def highlight_comments
      comments
        .order(:created_at)
        .map { |c| c.slice(:id, :content, :start_block_id, :end_block_id,
                           :start_offset, :end_offset, :created_at) }
    end
  end
end
```

- Uses the existing `has_many :comments` association — no new query scopes on `Comment`.
- `slice` keeps unrelated columns out of the payload; the Array of Hashes serializes cleanly via `.to_json`

### `app/models/document.rb`

Add the concern alongside the existing ones:

```ruby
class Document < ApplicationRecord
  include Documents::FileTypeable, Documents::AstParseable,
          Documents::FileSyncable, Documents::Highlightable
  # ...
end
```

(No change to `app/models/comment.rb` — it stays a thin AR model with just its associations and validations.)

---

## 2. Controller — `app/controllers/documents_controller.rb`

In `show`, add a single line (controller stays thin, calls the model):

```ruby
@comment_payload = @document.highlight_comments
```

---

## 3. View — `app/views/documents/show.html.erb`

### Attach the new controller
On `.document__paper`, stack the controller:

```erb
<div class="document__paper" data-controller="text-selection comment-highlight">
```

### Add offset hidden fields
Inside the existing form, next to the other hidden fields:

```erb
<%= f.hidden_field :start_offset, data: { text_selection_target: "startOffset" } %>
<%= f.hidden_field :end_offset, data: { text_selection_target: "endOffset" } %>
```

### Inject comment data
A JSON script tag is the cleanest way to hand data to Stimulus without globals:

```erb
<script type="application/json" data-comment-highlight-target="source">
  <%= @comment_payload.to_json.html_safe %>
</script>
```

### Add the popover element
Sibling to `.document__selection-form` (inside `.document__paper` so it shares the absolute positioning context):

```erb
<div class="document__comment-popover" data-comment-highlight-target="popover">
  <div class="document__comment-popover-header">
    <span class="document__comment-popover-date" data-comment-highlight-target="popoverDate"></span>
    <button type="button" class="document__comment-popover-close"
            data-action="click->comment-highlight#hidePopover" aria-label="Close">&times;</button>
  </div>
  <div class="document__comment-popover-body" data-comment-highlight-target="popoverBody"></div>
</div>
```

---

## 4. JS — `app/javascript/controllers/text_selection_controller.js`

### Add targets
Append `startOffset`, `endOffset` to `static targets`.

### New helper: `offsetWithinBlock(textNode, localOffset, blockEl)`
Character offset of `textNode` within the concatenated text content of `blockEl`:

- TreeWalker rooted at `blockEl`, `NodeFilter.SHOW_TEXT`.
- Walk until `textNode` is reached, summing `node.textContent.length` of prior nodes.
- Return the running sum + `localOffset`.
- If `textNode` is not a descendant of `blockEl` (defensive), return `localOffset`.

### Compute offsets in `evaluateSelection()` — **before `highlightRange`**
`highlightRange` mutates text nodes via `splitText`, which corrupts offsets. Capture first:

1. After `collectBlockIds(range)` returns `blockIds`, identify:
   - `startBlockEl = document.getElementById(blockIds[0])`
   - `endBlockEl   = document.getElementById(blockIds[blockIds.length - 1])`
2. Compute:
   - `startOffset = this.offsetWithinBlock(range.startContainer, range.startOffset, startBlockEl)`
   - `endOffset   = this.offsetWithinBlock(range.endContainer,   range.endOffset,   endBlockEl)`
3. Pass these into `showButton(...)` and populate the new hidden fields there.

### Update `showButton` signature
Accept `startOffset` / `endOffset` and set `this.startOffsetTarget.value` / `this.endOffsetTarget.value`.

### Update `hideButton`
Clear the two new fields alongside the others.

### Edge case: element-node boundaries
If `range.startContainer`/`range.endContainer` is an element (not a text node), `localOffset` points to a child index. Walk to that child's first/last descendant text node and use its offset within the block. This keeps capture consistent with apply (the apply path also walks SHOW_TEXT).

---

## 5. JS — `app/javascript/controllers/comment_highlight_controller.js` (new)

### Targets
`source`, `popover`, `popoverBody`, `popoverDate`.

### `connect()`
1. Parse `JSON.parse(this.sourceTarget.textContent)` → array of comments.
2. For each comment, call `applyComment(comment)`.
3. Attach a delegated click listener on `this.element` (or on `this.contentTarget`-equivalent) that catches clicks on `[data-comment-id]` and opens the popover. (Delegated because marks are created dynamically.)
4. Keep `bound*` references and remove the listener in `disconnect()`.

### `applyComment(comment)`
Resolve the block elements:

- `startBlock = document.getElementById(comment.start_block_id)`
- `endBlock   = document.getElementById(comment.end_block_id)`
- Bail if either is missing (document changed since the comment was made — don't crash).

Determine the ordered list of blocks to highlight:

- If `startBlock === endBlock` → `[startBlock]`, wrap `[start_offset, end_offset]`.
- Else → walk `[id^="block-"]` in DOM order, slice from `startBlock` to `endBlock` inclusive. Wrap:
  - First block: `[start_offset, end_of_block_text]`
  - Intermediate blocks: `[0, end_of_block_text]` (full)
  - Last block: `[0, end_offset]`

For each (block, [from, to]) pair, call `wrapTextInBlock(block, from, to, comment.id)`.

### `wrapTextInBlock(blockEl, from, to, commentId)`
TreeWalker SHOW_TEXT rooted at `blockEl`. Maintain a running character cursor; for each text node whose range intersects `[from, to]`:

- Compute local overlap `[max(0, from - cursor), min(nodeLen, to - cursor)]`.
- If non-empty, `splitText` at the overlap bounds, create `<mark class="document__comment-highlight" data-comment-id="commentId">`, replace the middle text node.
- Advance cursor by `nodeLen`.

This mirrors the technique in `text_selection_controller.js#highlightRange`. To avoid duplication, extract a shared `wrapRangeInMarks(rootEl, from, to, { className, dataset })` helper into `app/javascript/utils/text_wrap.js` and import it from both controllers. If extraction proves awkward (importmap path config), inline the helper in each controller — acceptable trade-off.

### `showPopover(event)`
- Find the closest `[data-comment-id]` ancestor of the click target.
- Look up the comment in a `Map<id, comment>` built during `connect` (or `find` on the parsed array).
- Position the popover: `popover.style.left/top` relative to the mark's `getBoundingClientRect()` minus `this.element.getBoundingClientRect()`.
- Fill `popoverBodyTarget.textContent = comment.content` and `popoverDateTarget.textContent = new Date(comment.created_at).toLocaleString()`.
- `popover.style.display = "flex"`.

### `hidePopover()`
`popover.style.display = "none"`.

### Notes
- Distinct class `document__comment-highlight` so `text_selection_controller.js#clearActiveHighlight` (which targets `activeMarks` / `.document__selection-highlight`) never touches persisted marks.
- On submit (full redirect), DOM is wiped and rebuilt — no cleanup needed in `disconnect` beyond the delegated listener.

---

## 6. CSS — `app/assets/stylesheets/pages/document.css`

### Persisted highlight (distinct from the in-progress one)

```css
.document__comment-highlight {
  background: #fde68a;            /* amber-200 — visibly different from #fef08a */
  border-bottom: 2px solid #f59e0b;
  border-radius: 2px;
  color: inherit;
  padding: 0;
  cursor: pointer;
  transition: background-color 0.15s ease;
}

.document__comment-highlight:hover {
  background: #fcd34d;            /* amber-300 */
}
```

### Popover (mirrors `.document__comment-card`)

```css
.document__comment-popover {
  display: none;
  position: absolute;
  flex-direction: column;
  gap: 8px;
  padding: 12px 14px;
  background: #ffffff;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.12), 0 0 1px rgba(0, 0, 0, 0.1);
  z-index: 20;                    /* above the in-progress card */
  min-width: 280px;
  max-width: 360px;
}

.document__comment-popover-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 0.75rem;
  color: #6b7280;
}

.document__comment-popover-close {
  background: none;
  border: none;
  font-size: 1rem;
  line-height: 1;
  color: #6b7280;
  cursor: pointer;
  padding: 0 4px;
}

.document__comment-popover-close:hover {
  color: #1d1d1f;
}

.document__comment-popover-body {
  font-size: 0.875rem;
  line-height: 1.5;
  color: #1d1d1f;
  white-space: pre-wrap;
}
```

---

## Behavior Summary
- Select text → fill hidden fields including new `start_offset`/`end_offset` → submit → comment persisted with offsets.
- Reload document → `comment_highlight` controller parses the injected JSON and wraps each comment's range in `<mark class="document__comment-highlight">`.
- Click any persisted mark → popover opens at the mark with content + date.
- Close button (×) or selecting new text (unrelated) → popover hidden.
- In-progress selection highlight (`.document__selection-highlight`) and persisted highlights (`.document__comment-highlight`) coexist without interfering.

## Verification
`bin/rubocop` for Ruby. JS is plain Stimulus via importmap (no `package.json`); no JS lint configured.

Manual, via `bin/rails dev`:

1. Single-block comment: select text in one paragraph, comment, reload → that exact slice is amber-highlighted; click → popover shows content + date.
2. Multi-block comment: select from middle of paragraph A through middle of paragraph B → on reload, A is highlighted from start_offset to its end, B from its start to end_offset; any full blocks in between are fully highlighted.
3. Comment inside a `<code>` block / `<blockquote>` → wrapped without breaking inline styles.
4. Two comments on the same paragraph (non-overlapping ranges) → both render as separate marks, both clickable.
5. Reload after deleting a comment (if UI exists) or after document content changes such that a `block-XXXX` id no longer exists → controller bails silently (no JS error, no crash).
6. Click a highlight → popover positioned at the mark; close button hides it; clicking another mark moves the popover.
7. Inspect DevTools: persisted marks have `data-comment-id`; transient (in-progress) marks do not. Confirm `clearActiveHighlight()` only removes transient marks.

## Edge cases handled
- Element-node selection boundaries → resolve to descendant text node before computing offset.
- `<br>` (softbreak/linebreak) contributes no text node → consistent between capture and apply (both walk SHOW_TEXT).
- Offsets captured before `highlightRange` mutates the DOM.
- Missing block id on apply → skip that comment gracefully.
- Shared wrapping helper factored out to `app/javascript/utils/text_wrap.js` to avoid duplicating `highlightRange` logic; fall back to inlining if importmap path config is awkward.
