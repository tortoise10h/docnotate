# Comment Create via Turbo Stream — Flow

End-to-end flow for creating a comment without a full-page reload.

## Table Rendering Sample

This table is included as a UI fixture for checking table layout, per-cell selection,
and inline markdown rendering:

| Element | Rendering | Selection check |
|---|---|---|
| Header cell | **Bold heading** | Select this header text |
| Body cell | `inline code` | Select a single cell |
| Link cell | [Turbo Streams](https://turbo.hotwired.dev/handbook/streams) | Select across rows |
| Long content | Tables should remain readable on narrow screens | Check horizontal scrolling |

```
User
 │
 │ selects text → "Add Note" → types → clicks "Comment"
 ▼
┌────────────────────────────────────────────────────────────────┐
│  Browser / Turbo                                                │
│  form_with url: document_comments_path(@document)               │
│  submits POST /documents/:id/comments                           │
│  with Accept: text/vnd.turbo-stream.html                        │
└────────────────────────────────────────────────────────────────┘
 │
 ▼
┌────────────────────────────────────────────────────────────────┐
│  Rails Routing                                                  │
│  POST /documents/:document_id/comments → comments#create        │
└────────────────────────────────────────────────────────────────┘
 │
 ▼
┌────────────────────────────────────────────────────────────────┐
│  CommentsController#create                                      │
│  1. document = Document.find(params[:document_id])              │
│  2. comment  = document.comments.build(comment_params)          │
│  3. comment.save                                                │
│  4. @comment_payload = document.highlight_comments  (new JSON)  │
│  5. respond_to { |format| format.turbo_stream }                 │
└────────────────────────────────────────────────────────────────┘
 │
 ▼
┌────────────────────────────────────────────────────────────────┐
│  View: app/views/comments/create.turbo_stream.erb               │
│  Renders a Turbo Stream response with 4 instructions:           │
│                                                                 │
│  1. turbo_stream.replace "comment_payload_source"               │
│     → swaps the JSON <script> with fresh payload                │
│                                                                 │
│  2. turbo_stream.update "comment_create_error", ""              │
│     → clears any prior validation error                         │
│                                                                 │
│  3. turbo_stream.action :reset_create_form, "document_paper"    │
│     → invokes Turbo.StreamActions.reset_create_form             │
│                                                                 │
│  4. turbo_stream.action :reload_comments, "document_paper"      │
│     → invokes Turbo.StreamActions.reload_comments               │
└────────────────────────────────────────────────────────────────┘
 │
 │  Turbo processes these in document order
 ▼
┌────────────────────────────────────────────────────────────────┐
│  UI result                                                      │
│  • New amber highlight appears on the selected text             │
│  • Comment nav shows updated count                              │
│  • Copy-comments button + divider appear when comments exist    │
│  • Create card is collapsed                                     │
│  • No full-page reload, scroll position preserved               │
│  • Clicking the new highlight → showPopover() displays          │
│    the comment content + timestamp                              │
└────────────────────────────────────────────────────────────────┘
```

## How the two custom Turbo Stream actions trigger events

Turbo Stream `<action>` elements only know built-in actions (`replace`, `update`, `append`, etc.).
Extra actions are registered by assigning functions to `Turbo.StreamActions`:

```js
// app/javascript/turbo_stream_actions.js
import { Turbo } from "@hotwired/turbo-rails"

Turbo.StreamActions.reload_comments = function() {
  this.targetElements.forEach(el =>
    el.dispatchEvent(new CustomEvent("comment-highlight:reload", { bubbles: true }))
  )
}

Turbo.StreamActions.reset_create_form = function() {
  this.targetElements.forEach(el =>
    el.dispatchEvent(new CustomEvent("comment-create:reset", { bubbles: true }))
  )
}
```

When the stream response contains:

```erb
<%= turbo_stream.action :reset_create_form, "document_paper" %>
<%= turbo_stream.action :reload_comments, "document_paper" %>
```

Turbo looks up `Turbo.StreamActions.reset_create_form` and
`Turbo.StreamActions.reload_comments`, sets `this.targetElements` to the
matching DOM element(s) (here `#document_paper`), and calls each function.
Each function dispatches a bubbling custom event on `#document_paper`.

Those events are then routed to Stimulus controller methods because
`#document_paper` declares them in its `data-action` attribute:

```erb
<!-- app/views/documents/show.html.erb -->
<div class="document__paper" id="document_paper"
     data-controller="text-selection comment-highlight comment-copy"
     data-action="comment-highlight:reload->comment-highlight#reloadFromSource
                 comment-highlight:reload->comment-copy#loadComments
                 comment-create:reset->text-selection#hideButton">
```

So the full chain for the two actions is:

| Stream action | Custom action function | Event dispatched | Stimulus handler |
|---|---|---|---|
| `:reset_create_form, "document_paper"` | `Turbo.StreamActions.reset_create_form` | `comment-create:reset` on `#document_paper` | `text-selection#hideButton` |
| `:reload_comments, "document_paper"` | `Turbo.StreamActions.reload_comments` | `comment-highlight:reload` on `#document_paper` | `comment-highlight#reloadFromSource` and `comment-copy#loadComments` |

## Step-by-step execution after the stream response

### 1. JSON source is replaced first

```erb
<%= turbo_stream.replace "comment_payload_source" do %>
  <script type="application/json" id="comment_payload_source"
          data-comment-highlight-target="source"
          data-comment-copy-target="source">
    <%= @comment_payload.to_json.html_safe %>
  </script>
<% end %>
```

The `<script id="comment_payload_source">` now contains the new comment list,
including the just-created comment. This happens before any controller re-renders
so both `comment-highlight` and `comment-copy` read fresh data.

### 2. `reset_create_form` collapses the create UI

`Turbo.StreamActions.reset_create_form` dispatches `comment-create:reset` on
`#document_paper`. Stimulus routes it to `text-selection#hideButton`:

```js
// app/javascript/controllers/text_selection_controller.js
hideButton() {
  this.clearActiveHighlight()   // remove green selection marks
  this.buttonTarget.style.display = "none"
  this.commentInputTarget.style.display = "none"
  this.commentTextTarget.value = ""
  // hidden fields are also cleared
}
```

### 3. `reload_comments` re-renders existing comments

`Turbo.StreamActions.reload_comments` dispatches `comment-highlight:reload` on
`#document_paper`. Two controllers listen to the same event.

**comment-highlight controller**

```js
// app/javascript/controllers/comment_highlight_controller.js
reloadFromSource() {
  this.loadComments()
}

loadComments() {
  this.clearAllMarks()          // unwrap old amber highlights
  this.comments = JSON.parse(this.sourceTarget.textContent)
  this.applyAllComments()       // wrap each comment range in <mark>
  this.buildNavigableComments()
  this.updateNav()              // refresh 1 / N count
}
```

**comment-copy controller**

```js
// app/javascript/controllers/comment_copy_controller.js
loadComments() {
  const payload = JSON.parse(this.sourceTarget.textContent)
  this.orderedComments = payload
    .filter(comment => document.getElementById(comment.start_block_id))
    .sort(/* document order */)

  const visible = this.orderedComments.length > 0
  this.buttonTarget.style.display = visible ? "inline-flex" : "none"
  this.dividerTarget.style.display = visible ? "block" : "none"
}
```

## Ordering guarantee

Turbo Stream actions execute in document order. The template intentionally places:

1. `replace` of the JSON source first, so the new payload is in the DOM before re-rendering highlights.
2. `reset_create_form` second, collapsing the create card.
3. `reload_comments` last, re-applying highlights and refreshing the copy button from the fresh source.

## Files involved

- `app/controllers/comments_controller.rb`
- `app/views/comments/create.turbo_stream.erb`
- `app/views/documents/show.html.erb`
- `app/javascript/turbo_stream_actions.js`
- `app/javascript/controllers/text_selection_controller.js`
- `app/javascript/controllers/comment_highlight_controller.js`
- `app/javascript/controllers/comment_copy_controller.js`
- `app/assets/stylesheets/pages/document.css`
