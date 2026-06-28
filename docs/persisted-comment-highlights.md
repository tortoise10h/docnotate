# Persisted Comment Highlights

## Overview

When a user saves a comment on a document, the application stores enough information to redraw the highlighted text on later visits. On page load, a Stimulus controller reads the saved comments and wraps each comment's range in `<mark class="document__comment-highlight">` elements. Clicking a persisted highlight opens a small popover with the comment body and creation date.

This is separate from the transient yellow highlight used while a comment is being composed. The two highlight types use different CSS classes and do not interfere with each other.

## Data Stored per Comment

Each comment carries four anchoring fields in addition to its body:

| Field | Meaning |
|-------|---------|
| `start_block_id` | `id` of the block where the selection begins (e.g. `block-abc123`) |
| `end_block_id` | `id` of the block where the selection ends |
| `start_offset` | Character offset within the **start block's** concatenated text |
| `end_offset` | Character offset within the **end block's** concatenated text |

`start_offset` and `end_offset` are measured against the block's full text content, obtained by walking all descendant `Node.TEXT_NODE` nodes in document order and summing their lengths.

### Example

For a paragraph rendered as:

```html
<p id="block-abc123">Simplify <code>resolve_file_path</code> to consider <code>params[:file_path]</code>.</p>
```

The text nodes are:

1. `"Simplify "` (9 chars)
2. `"resolve_file_path"` (17 chars)
3. `" to consider "` (15 chars)
4. `"params[:file_path]"` (20 chars)
5. `"."` (1 char)

Total block length = 62. Selecting `"resolve_file_path to consider"` would store:

- `start_block_id`: `block-abc123`
- `end_block_id`: `block-abc123`
- `start_offset`: 9
- `end_offset`: 9 + 17 + 15 = 41

## Capturing Offsets When a Comment Is Created

The capture happens in `text_selection_controller.js` before the transient highlight is rendered, because `splitText` mutations would corrupt the offsets.

### Step 1: Find the leaf blocks that contain the selection

`collectBlockIds()` queries every element whose `id` starts with `block-` and keeps only **leaf blocks** — blocks that are not ancestors of another selected block. This prevents a nested paragraph inside a list from being recorded as the enclosing list.

```js
const selectedBlocks = allBlocks.filter(block => blockContainsSelectedText(range, block))
return selectedBlocks
    .filter(block => !selectedBlocks.some(other => block !== other && block.contains(other)))
    .map(block => block.id)
```

A block "contains selected text" when at least one of its descendant text nodes has a non-empty overlap with the range.

### Step 2: Resolve element boundaries to text nodes

Browsers sometimes place a range boundary on an element node instead of a text node. For example, a selection ending at the boundary of a `<code>` tag may report the `<code>` element as `range.endContainer` with a child-index offset.

`resolveTextNode()` walks to the nearest descendant text node:

- For a **start** boundary, it returns the first text node inside the child at the given index.
- For an **end** boundary, it returns the last text node inside the child at the given index.

### Step 3: Compute offsets within the leaf blocks

`offsetWithinBlock()` walks the text nodes of the start/end block, summing lengths until it reaches the boundary text node, then adds the local offset inside that text node.

### Step 4: Populate hidden form fields

The computed values are written into the hidden form fields and submitted with the comment.

## Re-applying Highlights on Page Load

The `comment_highlight_controller.js` handles the read side.

### Data injection

The server serializes `document.highlight_comments` as a JSON array inside a `<script type="application/json">` tag in `app/views/documents/show.html.erb`. The controller parses this array in `connect()`.

### Determining which blocks to highlight

For each comment:

1. Look up `startBlock = document.getElementById(start_block_id)` and `endBlock = document.getElementById(end_block_id)`.
2. If either is missing (document changed since the comment was made), skip the comment.
3. Collect every `[id^="block-"]` element between `startBlock` and `endBlock` in DOM order.

For each block in that list:

- **First block**: highlight from `start_offset` to the end of the block.
- **Intermediate blocks**: highlight the entire block.
- **Last block**: highlight from the start of the block to `end_offset`.

If `startBlock === endBlock`, the range is `[start_offset, end_offset]` inside the single block.

### Wrapping text in marks

`wrapTextRange()` walks the text nodes of one block while tracking a running character cursor. For each text node whose range intersects `[from, to)`:

1. Compute the local overlap bounds.
2. `splitText()` at the end bound, then at the start bound.
3. Replace the middle text node with `<mark class="document__comment-highlight" data-comment-id="comment.id">`.

The walker collects all overlapping slices **before** mutating anything. Mutating while walking can cause the walker to re-enter the newly-created mark and loop forever.

## Multi-Block Highlights

A comment can span several blocks. For example, a selection starting in the middle of paragraph A and ending in the middle of paragraph B stores:

- `start_block_id`: A
- `end_block_id`: B
- `start_offset`: offset within A
- `end_offset`: offset within B

On reload:

- A is highlighted from `start_offset` to its end.
- Any full blocks between A and B are highlighted entirely.
- B is highlighted from its start to `end_offset`.

## Nested Blocks

Documents can contain nested block-level nodes, such as a paragraph inside a list item inside a list. Because both the list and the paragraph have `id="block-..."`, the capture logic must choose the innermost block.

`collectBlockIds()` filters out ancestor blocks, so the stored IDs point to the actual leaf blocks that contain the selected text. Offsets are then relative to those leaf blocks, which keeps the re-applied highlight precise.

## Popover

Persisted highlights are clickable. A delegated click listener on `.document__content` catches clicks on `.document__comment-highlight`, looks up the comment by `data-comment-id`, and positions a popover near the clicked mark. The close button hides the popover.

## Files Involved

- `app/models/documents/highlightable.rb` — shapes the comment payload for the client.
- `app/models/document.rb` — includes the `Highlightable` concern.
- `app/controllers/documents_controller.rb` — exposes `@comment_payload` to the view.
- `app/views/documents/show.html.erb` — stacks `comment-highlight` controller, injects JSON data, and renders the popover.
- `app/javascript/controllers/text_selection_controller.js` — captures block IDs and offsets when a comment is created.
- `app/javascript/controllers/comment_highlight_controller.js` — re-applies persisted highlights and handles the popover.
- `app/assets/stylesheets/pages/document.css` — styling for `.document__comment-highlight` and `.document__comment-popover`.
