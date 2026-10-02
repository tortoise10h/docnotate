# Edit existing comment

## Goal
Let users edit a comment's text directly from the comment popover, without deleting and recreating it. Only the `content` is editable; anchor metadata is untouched.

## Context
- Comments are nested under documents in `config/routes.rb`: `resources :comments, only: [:create, :destroy]`.
- `CommentsController` (`app/controllers/comments_controller.rb`) already responds with Turbo Streams for `create` and `destroy`, rebuilding `@comment_payload = @document.highlight_comments` on each.
- Existing Turbo Stream views:
  - `app/views/comments/create.turbo_stream.erb`
  - `app/views/comments/destroy.turbo_stream.erb`
- Custom Turbo Stream actions live in `app/javascript/turbo_stream_actions.js`: `reload_comments`, `reset_create_form`, `hide_popover`. They dispatch custom events on `#document_paper` that the `comment-highlight` and `text-selection` controllers listen for.
- The popover is currently inline in `app/views/documents/show.html.erb` (the `.document__comment-popover` block) and is driven by `app/javascript/controllers/comment_highlight_controller.js`, which maintains `commentsById`, `allMarks`, `navigableComments`, and `showPopover(mark, comment)`.
- The create form is owned by `text_selection_controller.js` and carries selection metadata (`start_block_id`, offsets, prefix/postfix, etc.). Reusing it for edit would couple the two controllers unnecessarily and drag selection state into the popover.
- `Comment` (`app/models/comment.rb`) only validates `content` presence; no model change needed.
- `app/assets/stylesheets/pages/document.css` already styles `.document__comment-textarea`, `.document__comment-actions`, `.document__comment-cancel`, and the popover header — reusable for the edit form.

## Plan

### 1. Routes — `config/routes.rb`
Add `:update` to the nested comments resource:

```ruby
resources :comments, only: [:create, :destroy, :update]
```

This yields `PATCH /documents/:document_id/comments/:id` → `document_comment_path(document, comment)` (the same helper already used by `destroy`).

### 2. Controller — `app/controllers/comments_controller.rb`
Add an `update` action mirroring the existing `create`/`destroy` Turbo Stream contract:

```ruby
def update
  @comment = @document.comments.find(params[:id])

  if @comment.update(comment_params)
    set_comment_payload
    render :update
  else
    @edit_error = @comment.errors.full_messages.to_sentence
    set_comment_payload
    render :update, status: :unprocessable_entity
  end
end
```

- Scoping through `@document.comments.find(params[:id])` ensures cross-doc access raises `RecordNotFound` (404), matching `destroy`'s behavior.
- `comment_params` is reused unchanged (still permits anchor fields, which `update` ignores but doesn't hurt).
- No redirect anywhere; the page never reloads.

### 3. Turbo Stream view — `app/views/comments/update.turbo_stream.erb`
Following the same pattern as `create.turbo_stream.erb`:

```erb
<%= turbo_stream.replace "comment_payload_source" do %>
  <script type="application/json" id="comment_payload_source"
          data-comment-highlight-target="source"
          data-comment-copy-target="source">
    <%= @comment_payload.to_json.html_safe %>
  </script>
<% end %>

<% if @edit_error.present? %>
  <%= turbo_stream.update "comment_edit_error", @edit_error %>
<% else %>
  <%= turbo_stream.update "comment_edit_error", "" %>
<% end %>

<%= turbo_stream.action :reload_comments, "document_paper" %>
```

- On 422, the source is replaced with unchanged content (so a reload won't drop anything visually); `#comment_edit_error` shows the validation message inline. The textarea's value is **not** reset — `turbo_stream.update "comment_edit_error"` only touches the error `<p>` element, leaving the form untouched.
- `reload_comments` re-applies highlights from the fresh source, so the edited comment's marks reflect any unchanged anchors (update only touches `content`).

### 4. Views — popover extraction + edit mode

#### 4a. Extract the popover to `app/views/comments/_popover.html.erb`
Per AGENTS.md ("split into partial to simplify the main view file"), extract the inline `.document__comment-popover` block from `show.html.erb` into a partial. The popover is now a self-contained component with display + edit modes, so it benefits from being its own file.

Render it from `show.html.erb`:

```erb
<%= render "comments/popover", document: @document %>
```

#### 4b. Popover partial with display + edit modes
The popover hosts display mode + edit mode, with Edit/Delete/Close header actions. The edit `<form>` is a real form submitted via Turbo (no `fetch`), with the action/method set dynamically per comment.

```erb
<div class="document__comment-popover" data-comment-highlight-target="popover"
     data-comment-highlight-update-url-template-value="<%= document_comment_path(document, ":id") %>">
  <div class="document__comment-popover-header">
    <span class="document__comment-popover-date" data-comment-highlight-target="popoverDate"></span>
    <div class="document__comment-popover-actions">
      <%= form_with url: document_comment_path(document, 0), method: :delete, class: "document__comment-delete-form", data: { comment_highlight_target: "deleteForm" } do |f| %>
        <%= f.button type: :submit, class: "document__comment-delete", aria: { label: "Delete comment" } do %>
          <!-- trash icon -->
        <% end %>
      <% end %>
      <button type="button" class="document__comment-popover-edit"
              data-action="click->comment-highlight#editComment" aria-label="Edit comment">
        <!-- pencil icon -->
      </button>
      <button type="button" class="document__comment-popover-close"
              data-action="click->comment-highlight#hidePopover" aria-label="Close">&times;</button>
    </div>
  </div>

  <p class="document__comment-destroy-error" id="comment_destroy_error"></p>

  <div class="document__comment-popover-body" data-comment-highlight-target="popoverBody"></div>

  <div class="document__comment-popover-edit-body" data-comment-highlight-target="popoverEditBody" hidden>
    <%= form_with url: "#", html: { class: "document__comment-edit-form", data: { comment_highlight_target: "editForm" } } do |f| %>
      <%= f.text_area :content, class: "document__comment-textarea",
            data: { comment_highlight_target: "popoverEditText",
                    controller: "auto-resize-textarea",
                    action: "input->auto-resize-textarea#resize" } %>
      <p class="document__comment-edit-error" id="comment_edit_error" data-comment-highlight-target="editError"></p>
      <div class="document__comment-actions">
        <button type="button" class="document__comment-cancel" data-action="click->comment-highlight#cancelEdit">Cancel</button>
        <%= f.button type: :submit, class: "button" do %>
          <span>Save</span>
        <% end %>
      </div>
    <% end %>
  </div>
</div>
```

- The edit form's `action` and `method` are set dynamically in `editComment()` using the `updateUrlTemplate` value, since the URL depends on the runtime comment id.
- Existing display body and delete form move in unchanged; only the Edit button and edit body are new.
- The `updateUrlTemplateValue` uses `:id` as a placeholder (URL-encoding-safe enough for integer ids), replaced at runtime.

### 5. JavaScript — `app/javascript/controllers/comment_highlight_controller.js`

#### New targets & value
```js
static targets = [
  "source", "popover", "popoverBody", "popoverDate", "deleteForm",
  "nav", "navCurrent", "navTotal",
  "popoverEditBody", "popoverEditText", "editForm", "editError"
]

static values = { updateUrlTemplate: String }
```

Track the currently open comment so we can re-anchor after a reload:
```js
this.currentComment = null
this.currentMark = null
```

#### `showPopover(mark, comment)` — reset to display mode
Store the open comment/mark and call `exitEditMode()` so opening a different comment discards any in-progress edit:
```js
showPopover(mark, comment) {
  const markRect = mark.getBoundingClientRect()
  const containerRect = this.element.getBoundingClientRect()

  this.currentComment = comment
  this.currentMark = mark
  this.popoverBodyTarget.textContent = comment.content
  this.popoverDateTarget.textContent = new Date(comment.created_at).toLocaleString()
  this.deleteFormTarget.action = `/documents/${this.documentId}/comments/${comment.id}`

  this.exitEditMode()
  this.popoverTarget.style.display = "flex"
  this.popoverTarget.style.left = `${markRect.left - containerRect.left}px`
  this.popoverTarget.style.top = `${markRect.bottom - containerRect.top + 4}px`
}
```

#### Edit mode toggle helpers
```js
editComment() {
  if (!this.currentComment) return
  this.editFormTarget.action = this.updateUrlTemplateValue.replace(":id", this.currentComment.id)
  this.editFormTarget.method = "patch"   // Rails fakes PATCH via _method on submit
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
```

The edit form is a real Turbo-enabled `form_with`, so submitting it (via the Save button or Enter) is intercepted by Turbo Drive natively — no manual `requestSubmit()` or `fetch` needed.

#### `reloadFromSource()` — re-anchor after edit
The existing `reloadFromSource` handler runs on every `reload_comments` dispatch. Extend it so the popover stays open and re-anchors to the same comment's freshly-recreated mark after an edit:

```js
reloadFromSource() {
  const openCommentId = this.currentComment?.id

  this.loadComments()

  if (openCommentId == null) return

  const updated = this.commentsById.get(openCommentId)
  if (!updated) {
    // Open comment was deleted — popover already hidden by hide_popover action
    this.currentComment = null
    this.currentMark = null
    return
  }

  const newMark = this.allMarks.find(m => Number(m.dataset.commentId) === updated.id)
  if (newMark) this.showPopover(newMark, updated)
}
```

- After **create**: no popover open (`openCommentId == null`) → just rebuild marks.
- After **update**: the open comment's id is still in `commentsById` → re-anchor to the fresh mark; popover shows updated content without a full-page reload. `showPopover` calls `exitEditMode()` so the edit form collapses back to display mode showing the new content.
- After **destroy**: the open comment's id is gone from `commentsById` → clear state; `hide_popover` action already hid the popover visually.

#### `hidePopover()` — also exit edit mode
```js
hidePopover() {
  this.exitEditMode()
  this.popoverTarget.style.display = "none"
}
```

### 6. CSS — `app/assets/stylesheets/pages/document.css`
Add small styles for the Edit button and the edit body. Reuse existing `.document__comment-textarea`, `.document__comment-actions`, `.document__comment-cancel`, and `.button` classes for the edit form itself.

```css
.document__comment-popover-edit {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 22px;
  height: 22px;
  padding: 0;
  background: none;
  border: none;
  border-radius: 4px;
  color: #6b7280;
  cursor: pointer;
  transition: color 0.15s ease, background-color 0.15s ease;
}

.document__comment-popover-edit:hover {
  color: #1d1d1f;
  background: #e5e7eb;
}

.document__comment-edit-error {
  margin: 0;
  font-size: 0.75rem;
  color: #dc2626;
}

.document__comment-edit-error:empty {
  display: none;
}
```

No new styles needed for the edit body container — `hidden` attribute handles visibility.

### 7. Tests — `test/controllers/comments_controller_test.rb`
Add tests following the existing create/destroy test conventions:

```ruby
test "update patches content and renders turbo_stream" do
  # ... setup comment ...
  patch document_comment_path(document, comment),
       params: { content: "updated body" }, as: :turbo_stream
  assert_response :ok
  assert_equal "updated body", comment.reload.content
  assert_match %r{turbo-stream}, response.content_type
end

test "update with blank content renders turbo_stream 422 and does not change" do
  # ... setup comment with original_content ...
  patch document_comment_path(document, comment),
       params: { content: "" }, as: :turbo_stream
  assert_response :unprocessable_entity
  assert_equal original_content, comment.reload.content
end

test "update with foreign comment id raises not found" do
  # ... setup other_comment under a different document ...
  assert_raises(ActiveRecord::RecordNotFound) do
    patch document_comment_path(document, other_comment),
         params: { content: "x" }, as: :turbo_stream
  end
end
```

No model test changes — `Comment`'s `validates :content, presence: true` already covers the empty-content case.

## Behavior Summary
- Click any persisted comment's highlight → popover shows content + date + Edit + Delete + Close.
- Click Edit → textarea appears prefilled, auto-resized, focused; Save/Cancel visible; display body hidden.
- Edit text → Save → native Turbo form PATCH → `update.turbo_stream.erb` replaces source + dispatches `reload_comments` → controller unwraps all marks, re-wraps from fresh source, re-anchors popover to same comment's mark with updated content. No page reload.
- Edit text → Cancel → popover reverts to display mode; content unchanged; no network request.
- Save with empty content → 422 returns; `#comment_edit_error` shows message; textarea still populated; comment content in DB unchanged; marks unchanged.
- Open comment A, edit, then click another mark B → A's edit state discarded (via `showPopover` → `exitEditMode`), B opens in display mode; A is unchanged.

## Risks / Open questions
- **Popovers anchored against detached marks after reload**: `reloadFromSource` re-anchors to fresh marks, so the popover doesn't jump or disappear after an edit.
- **Double-submit on Save**: a fast double-click could fire two PATCHes. Optional polish: disable Save/Cancel while in-flight via a `turbo:submit-start`/`turbo:submit-end` listener. Leaving it out for the first version.
- **Edit vs. create form reuse**: intentionally using a separate form inside the popover to avoid coupling `text_selection_controller` and `comment_highlight_controller`. The create form carries selection metadata edit doesn't need.
- **Textarea value preservation on 422**: `turbo_stream.update "comment_edit_error"` only touches the error `<p>`; the textarea (a separate element) keeps the user's input.
- **Cross-document access**: `document.comments.find(params[:id])` raises `RecordNotFound` → 404. Turbo Stream response with 404 doesn't include `reload_comments`, so state stays consistent.