# Edit, Delete & Create Comments via Turbo Stream

## Overview
The create/comment pipeline currently has poor UX: `text_selection_controller.js` captures selection metadata, `CommentsController#create` persists, then **reloads the entire `show` view** — re-executing AST parsing and re-rendering all markdown on every comment. Three gaps need fixing together:

1. **Update (and edit-on-create)** — the popover shows the comment body as read-only text; when a user wants to adjust wording after saving (or even right after creating), there's no path.
2. **Delete** — there is no way to remove a comment and its highlight at all.
3. **Create reloads the whole page** — even a successful create re-parses the entire AST; the user sees a flash and loses scroll position.

All three flows will be migrated to **Hotwire Turbo Stream** so only the affected DOM is touched. The same `reload_comments` custom Turbo Stream action is reused for create/update/destroy: the controller unwraps existing comment marks, re-reads the freshly-replaced JSON source, and re-applies highlights — uniform code path, no full-page reload, no AST re-parse.

## Scope
- **Create** (`POST /documents/:document_id/comments`) — refactor `CommentsController#create` to render `create.turbo_stream.erb` instead of redirecting. The existing `text_selection_controller.js` form submit is intercepted by Turbo Drive natively; on success the source `<script>` is replaced, `reload_comments` fires, and the create card collapses (no redirect).
- **Update** (`PATCH /documents/:document_id/comments/:id`) — only `content` is editable; anchor metadata is untouched.
- **Delete** (`DELETE /documents/:document_id/comments/:id`) — the comment's `<mark>` highlights must be unwrapped back to plain text. Reusing the same `reload_comments` path handles this naturally (the deleted comment is absent from the new payload, so its marks aren't recreated).
- **Partial extraction** — the popover (now with display + edit modes + edit/delete/close header actions + the edit form) becomes its own partial per AGENTS.md ("split into partial to simplify"). The create card also becomes a partial for symmetry.
- Maintain AGENTS.md: thin controllers call the AR model directly; no service objects; model layer unchanged.

### Existing context (relevant)
- `config/routes.rb` nests `resources :comments, only: [:create]` under `documents` → `document_comments_path(@document)`. Adding `[:update, :destroy]` yields `document_comment_path(@document, comment)` for PATCH/DELETE. The existing create route is reused.
- `app/controllers/comments_controller.rb` only has `create`; `comment_params` already permits `:content` + anchor fields, reusable across all three actions.
- `app/models/documents/highlightable.rb#highlight_comments` already includes `:id, :content, ...` — the payload reflects the latest persisted state after any mutation. No model change needed.
- `app/views/documents/show.html.erb` already renders `.document__comment-popover` (lines 45–51) inline and `.document__comment-card` (the create form's textarea+actions) inline; both will be extracted to partials.
- `app/javascript/controllers/comment_highlight_controller.js` already maintains `commentsById`, `allMarks`, `navigableComments`, and `showPopover(mark, comment)`. Adding edit/delete state + a reload handler is localized.
- `app/javascript/controllers/text_selection_controller.js` already drives the create flow: hidden fields → `showCommentInput` → native form submit. With Turbo Drive on (it is — `application.js` imports `@hotwired/turbo-rails`), the existing `<%= form_with url: document_comments_path(@document) %>` submit will be intercepted by Turbo automatically **as long as the controller responds to Turbo Stream requests**. Only the `create` action's response format needs to change from redirect to `turbo_stream`.
- `csrf_meta_tags` is in `app/views/layouts/application.html.erb:9` — Turbo handles CSRF automatically for native forms.
- `wrapRangeInMarks` already exists in `app/javascript/utils/text_wrap.js` and is reusable; no DOM-wrapping duplication.
- No existing turbo_stream views — these will be the project's first (`app/views/comments/create.turbo_stream.erb`, `update.turbo_stream.erb`, `destroy.turbo_stream.erb`).

---

## 1. Routes — `config/routes.rb`

Add `:update, :destroy` to the nested comments resource (create is already there):

```ruby
resources :comments, only: [:create, :update, :destroy]
```

This generates:
- `POST   /documents/:document_id/comments`      → `document_comments_path(document)`
- `PATCH  /documents/:document_id/comments/:id`  → `document_comment_path(document, comment)`
- `DELETE /documents/:document_id/comments/:id`  → same helper

---

## 2. Controller — `app/controllers/comments_controller.rb`

All three actions share a small private helper so the controller stays thin:

```ruby
class CommentsController < ApplicationController
  def create
    document = Document.find(params[:document_id])
    comment = document.comments.build(comment_params)

    if comment.save
      @comment_payload = document.highlight_comments
      respond_to { |format| format.turbo_stream }
    else
      @create_error = comment.errors.full_messages.to_sentence
      @comment_payload = document.highlight_comments
      respond_to do |format|
        format.turbo_stream { render :create, status: :unprocessable_entity }
      end
    end
  end

  def update
    document = Document.find(params[:document_id])
    comment = document.comments.find(params[:id])

    if comment.update(comment_params)
      @comment_payload = document.highlight_comments
      respond_to { |format| format.turbo_stream }
    else
      @edit_error = comment.errors.full_messages.to_sentence
      @comment_payload = document.highlight_comments
      respond_to do |format|
        format.turbo_stream { render :update, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    document = Document.find(params[:document_id])
    comment = document.comments.find(params[:id])
    comment.destroy!

    @comment_payload = document.highlight_comments
    respond_to { |format| format.turbo_stream }
  end

  private

  def comment_params
    params.permit(
      :content,
      :start_block_id, :end_block_id,
      :start_offset, :end_offset,
      :selected_text, :prefix_text, :postfix_text
    )
  end
end
```

- Every action rebuilds `@comment_payload = document.highlight_comments` and renders a Turbo Stream — uniform contract. There's no redirect anywhere now; the page never reloads.
- `destroy!` propagates on failure (rare for a single row); acceptable for the local tool.
- Scoping through `document.comments.find(params[:id])` ensures cross-doc access raises `RecordNotFound` (404), not 500.
- `comment_params` permit-list is unchanged (still includes anchor fields, which update/destroy don't need but won't hurt).

---

## 3. Turbo Stream views — `app/views/comments/`

Three small templates. A shared `_payload_replace.turbo_stream.erb` partial is **not** needed (only one `turbo_stream.replace` each); keeping them inline preserves readability.

### `create.turbo_stream.erb`
```erb
<%= turbo_stream.replace "comment_payload_source" do %>
  <script type="application/json" id="comment_payload_source"
          data-comment-highlight-target="source">
    <%= @comment_payload.to_json.html_safe %>
  </script>
<% end %>

<% if defined?(@create_error) && @create_error.present? %>
  <%= turbo_stream.update "comment_create_error", @create_error %>
<% else %>
  <%= turbo_stream.action :reset_create_form, "document_paper" %>
<% end %>

<%= turbo_stream.action :reload_comments, "document_paper" %>
```

- `reset_create_form` is a second custom Turbo Stream action that dispatches `comment-create:reset` so `text_selection_controller.js` collapses the create card + clears the transient selection highlight. Without it, after create the input card stays open and the transient highlight lingers.
- Without a create error path, the `#comment_create_error` element is emptied (so a retry after a failed submission clears the old error).

### `update.turbo_stream.erb`
```erb
<%= turbo_stream.replace "comment_payload_source" do %>
  <script type="application/json" id="comment_payload_source"
          data-comment-highlight-target="source">
    <%= @comment_payload.to_json.html_safe %>
  </script>
<% end %>

<% if defined?(@edit_error) && @edit_error.present? %>
  <%= turbo_stream.update "comment_edit_error", @edit_error %>
<% else %>
  <%= turbo_stream.update "comment_edit_error", "" %>
<% end %>

<%= turbo_stream.action :reload_comments, "document_paper" %>
```

- On 422, the same template renders with `@edit_error` populated; the source is replaced with unchanged content (so a reload won't drop anything visually), and `#comment_edit_error` shows the validation message inline. The textarea's value is **not** reset — Turbo Stream's `turbo_stream.update "comment_edit_error"` only touches the error `<p>` element, leaving the form (a separate element) untouched.

### `destroy.turbo_stream.erb`
```erb
<%= turbo_stream.replace "comment_payload_source" do %>
  <script type="application/json" id="comment_payload_source"
          data-comment-highlight-target="source">
    <%= @comment_payload.to_json.html_safe %>
  </script>
<% end %>

<%= turbo_stream.action :reload_comments, "document_paper" %>
<%= turbo_stream.action :hide_popover, "document_paper" %>
```

- After destroy, `reload_comments` rebuilds from the new payload — the deleted comment's id is no longer present, so its marks are unwrapped by `clearAllMarks()` and never re-wrapped. Then `hide_popover` closes the (now stale) popover.

---

## 4. View — `app/views/documents/show.html.erb`

### 4a. Add stable ids + listen for custom actions on the paper
On `.document__paper`, add `id="document_paper"` (Turbo Stream custom actions target it) and wire controller events:
```erb
<div class="document__paper" id="document_paper"
     data-controller="text-selection comment-highlight"
     data-action="comment-highlight:reload->comment-highlight#reloadFromSource
                  comment-highlight:hide-popover->comment-highlight#hidePopover
                  comment-create:reset->text-selection#hideButton">
```

### 4b. Mark the JSON source with a stable id
```erb
<script type="application/json" id="comment_payload_source"
        data-comment-highlight-target="source">
  <%= @comment_payload.to_json.html_safe %>
</script>
```

### 4c. Extract the create card + popover to partials
The inline `.document__selection-form` block (lines 21–43) and `.document__comment-popover` block (lines 45–51) both grow significantly with edit/delete/error UI. Per AGENTS.md ("split into partial to simplify the main view file"), extract them:

```erb
<div class="document__paper" id="document_paper" data-controller="..." data-action="...">
  <%= render "comments/create_form", document: @document %>
  <%= render "comments/popover", document: @document %>

  <div class="document__comment-nav" data-comment-highlight-target="nav">
    <%= render "comments/nav" %>   <%# already small; could inline if preferred %>
  </div>

  <script type="application/json" id="comment_payload_source" data-comment-highlight-target="source">
    <%= @comment_payload.to_json.html_safe %>
  </script>

  <div class="document__content" data-text-selection-target="content">
    <% @root_nodes.each do |root_node| %>
      <%= render "document_node", node: root_node %>
    <% end %>
  </div>
</div>
```

Note: `app/views/comments/` does not exist yet — this work creates it.

---

## 5. Partials — `app/views/comments/`

### `app/views/comments/_create_form.html.erb`
The existing inline create form moves here with one addition: an error element beneath the textarea, targetable by Turbo Stream's `#comment_create_error`. Otherwise behavior is unchanged — Turbo Drive intercepts the submit natively (`form_with` is Turbo-enabled by default in Rails 7).

```erb
<%= form_with url: document_comments_path(document), class: "document__selection-form",
              data: { text_selection_target: "form" } do |f| %>
  <%= f.hidden_field :start_block_id, data: { text_selection_target: "startBlockId" } %>
  <%= f.hidden_field :end_block_id,   data: { text_selection_target: "endBlockId" } %>
  <%= f.hidden_field :start_offset,   data: { text_selection_target: "startOffset" } %>
  <%= f.hidden_field :end_offset,     data: { text_selection_target: "endOffset" } %>
  <%= f.hidden_field :selected_text,  data: { text_selection_target: "selectedText" } %>
  <%= f.hidden_field :prefix_text,    data: { text_selection_target: "prefixText" } %>
  <%= f.hidden_field :postfix_text,   data: { text_selection_target: "postfixText" } %>

  <button class="document__selection-button"
          data-text-selection-target="button"
          data-action="click->text-selection#showCommentInput" type="button">
    <!-- + icon -->
    Add Note
  </button>

  <div class="document__comment-card" data-text-selection-target="commentInput">
    <%= f.text_area :content, placeholder: "Add your comment here...",
          class: "document__comment-textarea",
          data: { text_selection_target: "commentText",
                  controller: "auto-resize-textarea",
                  action: "input->auto-resize-textarea#resize" } %>
    <p class="document__comment-create-error" id="comment_create_error"></p>
    <div class="document__comment-actions">
      <button type="button" class="document__comment-cancel"
              data-action="click->text-selection#cancel">Cancel</button>
      <%= f.button type: "submit", class: "button" do %>
        <!-- + icon -->
        <span>Comment</span>
      <% end %>
    </div>
  </div>
<% end %>
```

### `app/views/comments/_popover.html.erb`
The popover hosts display mode + edit mode + edit/delete/close header actions. Edit-mode actions are wired to the `comment-highlight` controller; the edit `<form>` is real and submitted via Turbo (no `fetch`):

```erb
<div class="document__comment-popover" data-comment-highlight-target="popover"
     data-comment-highlight-update-url-template-value="<%= document_comment_path(document, ":id") %>">
  <div class="document__comment-popover-header">
    <span class="document__comment-popover-date" data-comment-highlight-target="popoverDate"></span>
    <div class="document__comment-popover-header-actions">
      <button type="button" class="document__comment-popover-edit"
              data-action="click->comment-highlight#editComment" aria-label="Edit comment">
        <!-- pencil icon -->
      </button>
      <button type="button" class="document__comment-popover-delete"
              data-action="click->comment-highlight#confirmDelete" aria-label="Delete comment">
        <!-- trash icon -->
      </button>
      <button type="button" class="document__comment-popover-close"
              data-action="click->comment-highlight#hidePopover" aria-label="Close">&times;</button>
    </div>
  </div>

  <div class="document__comment-popover-body" data-comment-highlight-target="popoverBody"></div>

  <div class="document__comment-popover-edit-body" data-comment-highlight-target="popoverEditBody" hidden>
    <%= form_with url: "#", local: false,
          html: { data: { comment_highlight_target: "editForm" } } do |f| %>
      <%= f.text_area :content,
            class: "document__comment-textarea",
            data: { comment_highlight_target: "popoverEditText",
                    controller: "auto-resize-textarea",
                    action: "input->auto-resize-textarea#resize" } %>
      <p class="document__comment-edit-error" id="comment_edit_error"
         data-comment-highlight-target="editError"></p>
      <div class="document__comment-actions">
        <button type="button" class="document__comment-cancel"
                data-action="click->comment-highlight#cancelEdit">Cancel</button>
        <button type="submit" class="button"
                data-action="click->comment-highlight#saveEdit">
          <span>Save</span>
        </button>
      </div>
    <% end %>
  </div>
</div>
```

- The edit form's `action` and `method` are set dynamically in `editComment()` using `this.updateUrlTemplateValue.replace(":id", comment.id)` — the URL depends on the runtime comment id, not known at render time.
- `local: false` is the Rails default for `form_with` in 7+; included explicitly for clarity.

### `app/views/comments/_nav.html.erb`
Small partial for the prev/next navbar (mostly mechanical extraction of lines 53–65). Optional — can be left inline if you prefer minimal partial count.

---

## 6. Custom Turbo Stream actions — `app/javascript/application.js`

Register three custom actions on Turbo (the file already imports `@hotwired/turbo-rails`):

```js
import "@hotwired/turbo-rails"
import { Turbo } from "@hotwired/turbo-rails"

Turbo.StreamActions.reload_comments = function() {
  this.targetElements.forEach(el =>
    el.dispatchEvent(new CustomEvent("comment-highlight:reload", { bubbles: true }))
  )
}

Turbo.StreamActions.hide_popover = function() {
  this.targetElements.forEach(el =>
    el.dispatchEvent(new CustomEvent("comment-highlight:hide-popover", { bubbles: true }))
  )
}

Turbo.StreamActions.reset_create_form = function() {
  this.targetElements.forEach(el =>
    el.dispatchEvent(new CustomEvent("comment-create:reset", { bubbles: true }))
  )
}
```

- Why custom actions (vs. tying to `turbo:submit-end` on the form): keep triggers explicit and decoupled from form lifecycle; lets create/update/destroy be authored anywhere without each controller needing to know "form finished successfully." The popover headless delete (transient form) especially benefits — it doesn't sit inside any tracked Stimulus form.
- Wire them via `data-action="..."` on `.document__paper` (see 4a). The dispatching element (`#document_paper`) is the controller's root, so the events bubble within the controller scope.

---

## 7. JS — `app/javascript/controllers/text_selection_controller.js` (create flow)

### Add the `comment-create:reset` listener
Already wired on `.document__paper` (4a) → `text-selection#hideButton`. `hideButton()` already:
- clears the transient selection highlight (`clearActiveHighlight()`)
- hides the button + comment-input card
- resets hidden fields + the textarea

So after a successful create, the custom action simply fires `hideButton()` — **no new code needed** in this controller. Just confirm `hideButton` resets `commentTextTarget.value = ""` (it does, line 245) so the next create starts empty.

### Optionally clear the create-error on new submission
Add an `input` action on the textarea so a fresh keystroke after a prior error clears the stale `#comment_create_error`:

```erb
data-action="input->auto-resize-textarea#resize
             input->text-selection#clearCreateError"
```
```js
clearCreateError() {
  const el = document.getElementById("comment_create_error")
  if (el) el.textContent = ""
}
```

Optional polish — not blocking; the Turbo Stream from create success already empties `#comment_create_error`.

---

## 8. JS — `app/javascript/controllers/comment_highlight_controller.js`

### New targets & state
```js
static targets = [
  "source", "popover", "popoverBody", "popoverDate",
  "nav", "navCurrent", "navTotal",
  "popoverEditBody", "popoverEditText", "editForm", "editError"
]

static values = { updateUrlTemplate: String }
```
In `connect()`:
```js
this.currentComment = null
this.currentMark = null
```

### Idempotent reload — `clearAllMarks()` + relaxed `loadComments()`
For the reload path to be safe across create/update/destroy, existing marks must be unwrapped before re-wrapping:

```js
clearAllMarks() {
  this.allMarks.forEach(mark =>
    mark.replaceWith(document.createTextNode(mark.textContent))
  )
  this.allMarks = []
  this.contentEl.normalize()
}
```

Update `loadComments()` so every call clears first:
```js
loadComments() {
  // parse as before
  this.comments = payload
  this.commentsById.clear()
  this.comments.forEach(comment => this.commentsById.set(comment.id, comment))
  this.clearAllMarks()
  this.applyAllComments()
  this.buildNavigableComments()
  this.updateNav()
}
```
- First call: `this.allMarks` is `[]` → `clearAllMarks()` is effectively a no-op + a harmless `normalize()` on the content root.
- Subsequent reloads (post-create/update/destroy): unwrap → `normalize()` merges adjacent text nodes → re-wrap from fresh payload. Uniform path.

### `showPopover(mark, comment)` — reset to display mode
```js
showPopover(mark, comment) {
  const markRect = mark.getBoundingClientRect()
  const containerRect = this.element.getBoundingClientRect()

  this.currentComment = comment
  this.currentMark = mark
  this.popoverBodyTarget.textContent = comment.content
  this.popoverDateTarget.textContent = new Date(comment.created_at).toLocaleString()

  this.exitEditMode()
  this.popoverTarget.style.display = "flex"
  this.popoverTarget.style.left = `${markRect.left - containerRect.left}px`
  this.popoverTarget.style.top  = `${markRect.bottom - containerRect.top + 4}px`
}
```

### Edit mode toggle helpers
```js
editComment() {
  if (!this.currentComment) return
  this.editFormTarget.action = this.updateUrlTemplateValue.replace(":id", this.currentComment.id)
  this.editFormTarget.method = "patch"
  this.popoverBodyTarget.hidden = true
  this.popoverEditBodyTarget.hidden = false
  this.popoverEditTextTarget.value = this.currentComment.content
  this.popoverEditTextTarget.focus()
  this.popoverEditTextTarget.dispatchEvent(new Event("input"))   // kick auto-resize
}

cancelEdit() { this.exitEditMode() }

exitEditMode() {
  this.popoverBodyTarget.hidden = false
  this.popoverEditBodyTarget.hidden = true
  this.popoverEditTextTarget.value = ""
  if (this.hasEditErrorTarget) this.editErrorTarget.textContent = ""
}

saveEdit(event) {
  event.preventDefault()
  this.editFormTarget.requestSubmit()   // Turbo intercepts → PATCH turbo_stream
}
```

### Delete flow — transient Turbo form
```js
confirmDelete(event) {
  if (!this.currentComment) return
  if (!window.confirm("Delete this comment? Its highlight will be removed.")) return

  const token = document.querySelector("meta[name='csrf-token']")?.content
  const form = document.createElement("form")
  form.method  = "post"                       // Rails fakes DELETE via _method
  form.action  = this.updateUrlTemplateValue.replace(":id", this.currentComment.id)
  form.dataset.turbo = "true"
  const method = document.createElement("input")
  method.type = "hidden"; method.name = "_method"; method.value = "delete"
  const csrf  = document.createElement("input")
  csrf.type  = "hidden"; csrf.name = "authenticity_token"; csrf.value = token || ""
  form.append(method, csrf)
  this.element.appendChild(form)
  form.requestSubmit()
  form.addEventListener("turbo:submit-end", () => form.remove(), { once: true })
}
```
Why a transient form instead of `fetch(DELETE)`: keeps the path uniform with the edit form — Turbo Stream response is consumed natively. (If you later prefer `fetch`, the same CSRF + manual `turbo-stream` parsing applies, but native submission is simpler.)

### `reloadFromSource(event)` — the Turbo Stream reload handler
Triggered by the `comment-highlight:reload` custom event from the custom Turbo stream action:

```js
reloadFromSource() {
  const openCommentId = this.currentComment?.id

  this.loadComments()

  if (openCommentId == null) return

  const updated = this.commentsById.get(openCommentId)
  if (!updated) {
    // The open comment was deleted — popover already hidden by hide_popover action
    this.currentComment = null
    this.currentMark = null
    return
  }

  // Update was edited: re-anchor popover to the freshly-recreated mark for the same comment
  const newMark = this.allMarks.find(m => Number(m.dataset.commentId) === updated.id)
  if (newMark) this.showPopover(newMark, updated)
}
```

- After **create**: no popover is open (`openCommentId == null`) → just rebuild marks; the new comment's marks appear.
- After **update**: the open comment's id is still in `commentsById` → re-anchor to the fresh mark; popover shows updated content with no full-page reload.
- After **destroy**: the open comment's id is gone from `commentsById` → clear state; `hide_popover` action already hid the popover visually.

### `hidePopover()` — also exit edit mode
```js
hidePopover() {
  this.exitEditMode()
  this.popoverTarget.style.display = "none"
}
```

---

## 9. CSS — `app/assets/stylesheets/pages/document.css`

Reuse `.document__comment-textarea` + `.document__comment-actions` (already styled for the create card — now shared by the popover's edit mode). Add small rules for the new header buttons + the two inline error styles:

```css
.document__comment-popover-header-actions {
  display: flex;
  align-items: center;
  gap: 4px;
}

.document__comment-popover-edit,
.document__comment-popover-delete {
  background: none;
  border: none;
  color: #6b7280;
  cursor: pointer;
  padding: 0 4px;
  display: inline-flex;
}

.document__comment-popover-edit:hover   { color: #1d1d1f; }
.document__comment-popover-delete:hover { color: #dc2626; }   /* red-600 */

.document__comment-create-error,
.document__comment-edit-error {
  margin: 0;
  font-size: 0.75rem;
  color: #dc2626;
}

.document__comment-create-error:empty,
.document__comment-edit-error:empty {
  display: none;
}
```

---

## Tests — `test/controllers/comments_controller_test.rb` (extend existing create test)

```ruby
test "create renders turbo_stream and adds comment" do
  document = ...
  assert_difference("Comment.count", +1) do
    post document_comments_path(document),
         params: { content: "hi", start_block_id: "block-1", ... },
         as: :turbo_stream
  end
  assert_response :ok
  assert_match %r{turbo-stream}, response.content_type
end

test "create with blank content renders turbo_stream 422" do
  post document_comments_path(document), params: { content: "" }, as: :turbo_stream
  assert_response :unprocessable_entity
  assert_match "content", response.body    # error message somewhere in stream
end

test "update patches content and renders turbo_stream" do
  comment = ...
  patch document_comment_path(document, comment),
       params: { content: "updated body" }, as: :turbo_stream
  assert_response :ok
  assert_equal "updated body", comment.reload.content
  assert_match %r{turbo-stream}, response.content_type
end

test "update with blank content renders turbo_stream 422 and does not change" do
  patch document_comment_path(document, comment),
       params: { content: "" }, as: :turbo_stream
  assert_response :unprocessable_entity
  assert_equal original_content, comment.reload.content
end

test "update with foreign comment id raises not found" do
  other_comment = ...    # comment under a different document
  assert_raises(ActiveRecord::RecordNotFound) do
    patch document_comment_path(document, other_comment),
         params: { content: "x" }, as: :turbo_stream
  end
end

test "destroy removes the comment and renders turbo_stream" do
  comment = ...
  assert_difference("Comment.count", -1) do
    delete document_comment_path(document, comment), as: :turbo_stream
  end
  assert_response :ok
end
```

No model test changes — `Comment`'s `validates :content, presence: true` already covers the empty-content cases.

---

## Behavior Summary
- **Create** — select text → click **Add Note** → type → **Comment** → Turbo PATCH (well, POST) → `create.turbo_stream.erb` replaces source + dispatches `reload_comments` + `reset_create_form` → new comment's marks appear in-place; create card collapses; transient highlight cleared. No full-page reload, no AST re-parse, scroll position preserved.
- **Update** — click any persisted mark → popover shows content + date + Edit + Delete + Close. Edit pencil → textarea (prefilled, auto-resized, focused) + Save/Cancel. Save → native Turbo form PATCH → `update.turbo_stream.erb` replaces source + dispatches `reload_comments` → controller unwraps all marks, re-wraps from fresh source, re-anchors popover to same comment's new mark with updated content. No reload.
- **Validation error** (create or update) — controller renders same template with 422 + populates `#comment_create_error` / `#comment_edit_error`; textarea values preserved; marks unchanged.
- **Delete** — Delete trash → `window.confirm` → transient Turbo form DELETE → `destroy.turbo_stream.erb` replaces source + dispatches `hide_popover` + `reload_comments` → popover hides; the deleted comment's marks vanish (unwrapped, never re-wrapped); nav count decrements.
- **Cancel** (edit) — `exitEditMode()` reverts to display mode; no submit.
- **Re-open** — `showPopover` calls `exitEditMode()` first, so no edit-state leak when navigating between comments.
- **Reload the document page** (e.g. nav away and back) — `@comment_payload` reflects the latest persisted state via `highlight_comments`; standard `connect()` path.

## Verification
`bin/rubocop` for Ruby. No JS lint configured.

Manual, via `bin/rails dev`:

1. **Create** without reload — select text → Add Note → type → Comment → watch Network tab: only one `POST /documents/:id/comments` request, `text/vnd.turbo-stream.html`, no follow-up document request, no page flash; new amber highlight appears at the selected range; create card collapsed; transient highlight gone.
2. **Create validation** — submit empty content → 422 returned; `#comment_create_error` shows "Content can't be blank"; textarea still focused; no DB row added; page intact.
3. Click any persisted comment's highlight → popover shows content + date; Edit + Delete icons visible in header.
4. Click Edit → textarea appears prefilled, auto-resized, focused; Save/Cancel visible; display body hidden.
5. Edit text → Save → Network: PATCH `/documents/:id/comments/:id` as `text/vnd.turbo-stream.html`; response replaces `#comment_payload_source`; popover re-anchors to same comment's mark; shows new content; no page reload; highlight count and position unchanged.
6. Edit text → Cancel → popover reverts; content unchanged; no network request.
7. Save with empty content → 422 returns; `#comment_edit_error` shows message; textarea still populated; comment content in DB unchanged; marks unchanged.
8. Click Delete → confirm dialog → yes → Network: DELETE; popover closes; deleted comment's highlights collapse back to plain text; nav count decrements; no page reload.
9. Click Delete → confirm dialog → cancel → nothing changes.
10. Open comment A, edit, then click another mark B → A's edit state discarded, B opens in display mode (no Edit save of A occurs; A unchanged).
11. Reload the page after update → new content persists (verified via `@comment_payload` reflecting DB state).
12. Reload after delete → deleted comment's marks absent; total count matches DB row count.
13. Inspect DevTools: PATCH and DELETE responses are `<turbo-stream>` fragments; no full HTML document reload.
14. Cross-document 404 — manually PATCH `/documents/A_id/comments/B_comment_id` (B belongs to another document) → 404; no DB change; no source replacement.

## Edge cases handled
- **No current comment** when Edit/Delete clicked → guard returns early.
- **Popovers anchored against detached marks after reload** — `reloadFromSource` re-anchors to fresh marks (or hides if deleted).
- **Double-submit on Save** — `requestSubmit()` is idempotent within a tick; optional `disabled` toggle on Save/Cancel while in-flight can be a polish follow-up.
- **Cross-document access** — `document.comments.find(params[:id])` raises `RecordNotFound` → 404. Turbo Stream response with 404 doesn't include the reload action → state stays consistent.
- **Create card stale error** — `create.turbo_stream.erb` empties `#comment_create_error` on success; the optional `clearCreateError` input handler clears it on first keystroke after a failed attempt.
- **First call to `loadComments()`** — `clearAllMarks()` is effectively a no-op (empty `allMarks`); `normalize()` on the content root is harmless.
- **Turbo Stream custom actions not registered** — if the `application.js` registration fails (e.g. import map misconfig), the actions are absent → `comment-highlight:reload` never fires → popover/UI shows stale content until next full reload. Optional guard: warn in `connect()` if `Turbo.StreamActions.reload_comments` is undefined.
- **Destroy fails** (rare) — `destroy!` raises; Rails returns 500; no source replaced; UI left in pre-delete state, marks intact; the transient form's `turbo:submit-end` listener still removes the transient form node.
- **Concurrent edits / multi-tab** — last write wins; not handled with optimistic locking (out of scope).
- **Mark re-creation after reload** — `clearAllMarks()` unwraps + `normalize()` merges adjacent text nodes; re-wrapping is deterministic given unchanged anchors (update doesn't touch them; destroy removes them from payload).

## Out of scope (follow-ups)
- **Optimistic UI** before PATCH resolves (currently waits for the Turbo Stream response).
- **Inline `turbo-confirm` with a custom modal** instead of `window.confirm` (would let us drop the transient-form approach and use a static DELETE form with `data-turbo-confirm`).
- **Refactoring `applyComment` to use `wrapRangeInMarks`** from `utils/text_wrap.js` — pure cleanup.
- **Broadcast creates/updates/deletes to other open tabs** via Turbo Streams + Action Cable — not needed for the single-user local tool.
- **Persisted partial invalidation** — if a document's underlying file changes on disk between create and update, anchors computed at create-time may now be stale. `applyComment` already bails silently on a missing block id; this plan doesn't add reconciliation.