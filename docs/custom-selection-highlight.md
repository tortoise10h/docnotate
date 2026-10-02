# Custom Persistent Selection Highlight

## Why We Replaced Native Highlighting

On the document show page, users create comments by selecting text. The original implementation relied on the browser's native `window.getSelection()` highlight. That created two UX problems:

1. **The highlight disappears on focus change.** As soon as the comment card receives focus, the browser clears the native selection, so the user loses the visual reference for what they selected.
2. **Risk of double rendering.** Keeping the native selection while showing a separate highlight can lead to overlapping or conflicting visuals.

To fix this, we now convert the live selection into a set of custom `<mark>` elements. The native selection is cleared immediately after wrapping, so the `<mark>` becomes the single, persistent source of truth for the in-progress comment highlight.

## Scope

- **Active selections only.** Only the current, unsaved comment selection is highlighted. Saved comments are not re-anchored or rendered as highlights — that is a separate feature.
- **One highlight at a time.** Starting a new selection removes any previous unsaved highlight.
- **No backend changes.** The existing database columns (`start_block_id`, `end_block_id`, `selected_text`, `prefix_text`, `postfix_text`) are still used. This work is purely frontend.

## High-Level Flow

```
User selects text
        │
        ▼
Extract selected text, block IDs, prefix, and postfix
        │
        ▼
Clear any previous active highlight
        │
        ▼
Wrap the selected text slices in <mark class="document__selection-highlight">
        │
        ▼
Remove the native selection
        │
        ▼
Show the "Add Note" button
        │
        ▼
User clicks "Add Note" → comment card opens, highlight stays visible
```

Cancellation, outside clicks, or starting a new selection all remove the `<mark>` elements and restore a clean DOM.

## How the Highlight Is Built

### 1. Capture the Live Selection

When the user releases the mouse inside the document content area, `evaluateSelection()` reads the current native selection:

```js
const selection = window.getSelection()
const selectedText = selection.toString().trim()
const range = selection.getRangeAt(0)
```

If the selection is empty or does not intersect any document block, the flow bails out.

### 2. Collect Block IDs

The selected range can span one or more block-level nodes. We collect the IDs of every `[id]` element inside the content container that intersects the range. The first and last IDs become `start_block_id` and `end_block_id` for the comment form.

### 3. Extract Prefix and Postfix

Before the native selection is cleared, we read up to 50 characters before the start offset and up to 50 characters after the end offset from the live range. These are stored in the hidden `prefix_text` and `postfix_text` fields and are used later to anchor saved comments.

### 4. Clear Previous Highlights

To enforce the "one active highlight at a time" rule, we first unwrap any existing `<mark>` elements:

```js
this.activeMarks.forEach(mark => {
    mark.replaceWith(document.createTextNode(mark.textContent))
})
this.activeMarks = []
this.contentTarget.normalize()
```

`normalize()` merges adjacent text nodes so the DOM is clean and future selections behave predictably.

### 5. Wrap the Range in `<mark>` Elements

This is the core of the feature. We cannot use `Range.surroundContents()` because selections can span multiple block-level elements, which would throw an `InvalidStateError`. Instead, we use a `TreeWalker` over all text nodes inside the content container:

```js
const walker = document.createTreeWalker(
    this.contentTarget,
    NodeFilter.SHOW_TEXT,
    null,
    false
)
```

For each text node that intersects the range, we compute the overlapping substring:

- If the node is `range.startContainer`, the overlap starts at `range.startOffset`; otherwise it starts at `0`.
- If the node is `range.endContainer`, the overlap ends at `range.endOffset`; otherwise it ends at the node's text length.

Nodes with no overlap are skipped.

For each overlapping slice, we split the text node and replace the middle part with a `<mark>`:

```js
const afterHighlight = textNode.splitText(endOffset)
const highlightNode = textNode.splitText(startOffset)
const mark = document.createElement("mark")

mark.className = "document__selection-highlight"
mark.textContent = highlightNode.textContent
parent.replaceChild(mark, highlightNode)
```

This handles:
- Single-paragraph selections.
- Selections spanning multiple paragraphs, headings, or lists.
- Selections inside inline elements such as `<code>`, `<strong>`, or `<a>`.

Each created `<mark>` is pushed into `this.activeMarks` so it can be removed later.

### 6. Clear the Native Selection

After the `<mark>` elements are in place, we clear the native selection so only the custom highlight remains:

```js
selection.removeAllRanges()
```

This is what makes the highlight survive focus changes and outside clicks.

### 7. Show the Comment Button

The "Add Note" button is positioned at the end of the last client rect of the original range. The captured values are written into the hidden form fields.

When the user clicks "Add Note", the comment card appears and receives focus. Because the visual highlight is now DOM-based rather than selection-based, it stays visible.

## How the Highlight Is Removed

The highlight is removed in three situations:

1. **Cancel button or outside click.** `hideButton()` calls `clearActiveHighlight()` first, then hides the button/card and resets the form fields.
2. **Starting a new selection.** A `mousedown` listener on the content container calls `clearActiveHighlight()` immediately, wiping the old mark before the new selection is finalized.
3. **Successful comment submission.** The existing controller redirects with a full page reload, which naturally rebuilds the DOM without any marks.

## Styling

The highlight is styled in `app/assets/stylesheets/pages/document.css`:

```css
.document__selection-highlight {
  background: #fef08a;
  border-radius: 2px;
  color: inherit;
  padding: 0;
}
```

- `background: #fef08a` gives a marker-yellow color.
- `color: inherit` prevents the browser's default `<mark>` styling from changing text color.
- `padding: 0` ensures the mark does not alter line metrics or wrapping.

## Files Involved

- `app/javascript/controllers/text_selection_controller.js` — all selection, highlighting, and cleanup logic.
- `app/assets/stylesheets/pages/document.css` — highlight appearance.

No models, migrations, controllers, or routes were changed.
