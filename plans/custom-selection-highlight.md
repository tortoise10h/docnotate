# Custom Persistent Selection Highlight

## Overview
Today, selecting text on the document show page relies on the browser's native `window.getSelection()` highlight. The comment form appears on `mouseup`, but the native highlight vanishes the moment the input takes focus or an outside click fires — poor UX. Replace native selection with a custom `<mark>`-based highlight that persists while the comment form is open and is only removed when we explicitly dismiss it.

## Scope
- **Active selection only.** Persist the highlight for the in-progress comment. Existing/saved comments are still not re-anchored or displayed — that is a separate feature.
- **One active highlight at a time.** Starting a new selection removes any prior unsaved highlight.
- **Clear the native selection once the `<mark>` is in place** so the highlight is pure, immune to focus loss, and there is no double-render. Prefix/postfix extraction still runs first (it reads the live range before clearing).
- **No model / migration / controller / routing changes.** The DB already stores `start_block_id`, `end_block_id`, `selected_text`, `prefix_text`, `postfix_text` (plus unused `start_offset`/`end_offset`). This work only touches the in-browser selection UX.

### Existing context (relevant)
- `app/views/documents/show.html.erb` hosts the form with hidden fields (`startBlockId`, `endBlockId`, `selectedText`, `prefixText`, `postfixText`, `commentText` targets) and a `data-text-selection-target="content"` container rendering `@root_nodes`.
- `CommentsController#create` redirects on success → full page reload → DOM wiped → no leftover marks after submit.
- No existing `<mark>`/highlight CSS. Only block-level highlight is `[id^="block-"]:target` (URL-fragment, unrelated).
- `_document_node.html.erb` emits `id="block-…"` on block-level nodes — used by `collectBlockIds`.

---

## 1. JS — `app/javascript/controllers/text_selection_controller.js`

### State
- Add instance field `this.activeMarks = []`, initialized in `connect`. Tracks the live `<mark>` elements for the current in-progress comment.

### New helper: `highlightRange(range)`
Walk all text nodes intersecting the range and wrap each overlapping slice in a `<mark class="document__selection-highlight">`. Handles selections spanning multiple blocks (where `surroundContents` would throw `InvalidStateError`).

- Use a `TreeWalker` rooted at `this.contentTarget`, `NodeFilter.SHOW_TEXT`.
- For each text node, compute overlap with the range:
  - If the node is the `range.startContainer`, overlap starts at `range.startOffset`; else `0`.
  - If the node is the `range.endContainer`, overlap ends at `range.endOffset`; else `node.textContent.length`.
  - Skip nodes with no overlap (start ≥ end).
- For each overlap, split the text node at the start and end of the overlap (`TextNode.splitText`), then wrap the middle text node in a freshly created `<mark>` via `document.createElement` + `parentNode.replaceChild` (or `surroundContents` on a single-node sub-range — safe here since the sub-range is contained in one text node).
- Push each created `<mark>` into `this.activeMarks`.
- Return the array.

### New helper: `clearActiveHighlight()`
- For each mark in `this.activeMarks`, replace it with its text content: `mark.replaceWith(document.createTextNode(mark.textContent))`.
- After all replacements, call `this.contentTarget.normalize()` to merge adjacent text nodes (the wrapping/splitting leaves fragmented text nodes; normalize restores clean DOM so future selections work correctly).
- Set `this.activeMarks = []`.

### Modify `evaluateSelection()`
Order matters — extract prefix/postfix from the live range first, then wrap, then clear native:

1. `selection = window.getSelection()`; if empty → `hideButton()` and return (existing).
2. `range = selection.getRangeAt(0)`; `collectBlockIds(range)`; bail if empty (existing).
3. `selectedText = selection.toString().trim()` (existing).
4. **New:** call `this.clearActiveHighlight()` to remove any prior active mark (one-active rule).
5. Read `prefixText`/`postfixText` from `range` (existing `extractPrefix`/`extractPostfix`) **before** clearing the native selection.
6. **New:** call `this.highlightRange(range)` to wrap the selection as marks.
7. **New:** call `window.getSelection().removeAllRanges()` so the native highlight disappears and the `<mark>` is the sole visual.
8. Position the button and populate hidden fields (existing `showButton` logic), using the values captured in steps 3 and 5 (pass them in) since `selection` is now empty.

### Modify `showCommentInput(event)`
- Drop the save/restore native-selection block (lines ~93–105): the native selection is already cleared; the mark persists independently of input focus.
- Keep the button→card toggle and `commentTextTarget.focus()`.

### Modify_MOUSEdown guard: add `mousedown` listener on `contentTarget` (in `connect`) calling `clearActiveHighlight()` so starting a new selection proactively wipes the prior mark. Keep the existing `mouseup` → `evaluateSelection` listener. Remember to remove the new listener in `disconnect`.

### Modify `hideButton()`
- Call `this.clearActiveHighlight()` at the top so both `cancel()` and outside-click dismissals remove the mark. Then keep the existing field-clearing logic.
- `cancel()` stays as a thin wrapper that calls `hideButton()` — no need for the separate `window.getSelection().removeAllRanges()` since native selection is already cleared by this point; harmless to leave it.

---

## 2. CSS — `app/assets/stylesheets/pages/document.css`

Add near the `.document__selection-button` block (BEM, page-scoped):

```css
.document__selection-highlight {
  background: #fef08a;   /* marker yellow */
  border-radius: 2px;
  color: inherit;
  padding: 0;
}
```

No padding/margin that would shift wrapping or alter line metrics — the mark replaces text without changing structure. `color: inherit` prevents the user-agent default for `<mark>` from changing text color.

---

## Behavior Summary
- Select text → `<mark>` wraps the slice, native selection cleared, highlight survives focusing the comment input.
- Submit → full-page redirect (existing flow), DOM wiped naturally — no cleanup needed.
- Cancel / outside-click → `clearActiveHighlight()` removes the mark, hidden fields reset.
- Start a new selection → prior mark cleared via the `mousedown` guard (and again at the top of `evaluateSelection`), new mark applied.
- Selections spanning multiple blocks/inline nodes are handled by the TreeWalker approach (not `surroundContents`).

## Verification
Reload the document show page and exercise:

1. Selection inside a single paragraph — mark wraps, comment card focuses without losing highlight.
2. Selection spanning two paragraphs — both slices wrapped, no JS error, hidden `start_block_id`/`end_block_id` correctly differ.
3. Selection spanning a heading + following paragraph — same as above.
4. Selection inside a `<code>` block — wrapped without breaking inline code styling.
5. Cancel button → mark removed, parent DOM normalized (verify via DevTools that text nodes re-merged, no stray split nodes).
6. Outside click (away from button/card, inside and outside paper) → mark removed.
7. Select text A, then without dismissing select text B → only B remains highlighted.
8. Submit a comment → page redirects/reloads, highlight gone, comment persisted (existing flow still works; hidden fields populated as before).

No lint/typecheck step required for plain Stimulus JS; ensure `bin/rails dev` serves the updated file (Hotwire picks up `app/javascript/controllers/*` via importmap/esbuild as configured).