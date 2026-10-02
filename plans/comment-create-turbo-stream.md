# Comment Create via Turbo Stream (no full-page reload)

## Goal
Stop reloading the whole documents#show page after creating a comment. Switch `CommentsController#create` to a Turbo Stream response that only replaces the comment-payload `<script>` source + resets the create card, so the new comment's highlight appears in place and scroll position is preserved.

## Context
- Current flow: `app/views/documents/show.html.erb` renders a Turbo-enabled `form_with url: document_comments_path(@document)` (line 21). On submit, Turbo Drive posts the form, but `CommentsController#create` (`app/controllers/comments_controller.rb:7`) calls `redirect_to open_documents_path(...)` → full document reload, re-parsing the whole AST and re-rendering all markdown on every comment.
- The view already embeds the persisted comments as JSON in `<script type="application/json" data-comment-highlight-target="source">` (`app/views/documents/show.html.erb:77-79`), consumed by `comment_highlight_controller.js#loadComments` on `connect()`. The controller already knows how to (re)apply highlights from this source — it just isn't re-run after a create.
- `comment_highlight_controller.js` already maintains `comments`, `commentsById`, `allMarks`, `navigableComments`, `applyAllComments`, `buildNavigableComments`, `updateNav`. A reload from source path only needs: unwrap existing marks + re-run `loadComments`.
- `text_selection_controller.js#hideButton` (line 240) already resets everything the create card needs after success — clears the transient selection highlight, hides button + comment-input, and empties the hidden fields + textarea. Reusable as the "reset create form" handler.
- `Document#highlight_comments` (`app/models/documents/highlightable.rb`) already returns the full post-mutation payload including the new comment; no model change needed.
- `@hotwired/turbo-rails` is already imported (`app/javascript/application.js:2`) and `csrf_meta_tags` is present in the layout — Turbo will natively intercept the existing `form_with` submit and request `text/vnd.turbo-stream.html` as soon as the controller action responds to `format.turbo_stream`. No form change needed.
- This is a strict subset of `plans/edit-existing-comment.md` (create portion only). Keeping it scoped here so the create UX fix can ship independently; the edit/delete plan can be revisited later without re-doing create.
- Existing test `test/integration/comments_test.rb` asserts `assert_redirected_to ...` — this will break and must be updated to assert a Turbo Stream response.

## Plan

### 1. Controller — `app/controllers/comments_controller.rb`
Replace the redirect with a Turbo Stream response. Keep the controller thin (AGENTS.md: business logic stays in the model layer; persistence here is already a one-liner AR call).

```ruby
class CommentsController < ApplicationController
  def create
    document  = Document.find(params[:document_id])
    comment   = document.comments.build(comment_params)

    if comment.save
      @comment_payload = document.highlight_comments
      respond_to { |format| format.turbo_stream }
    else
      @create_error   = comment.errors.full_messages.to_sentence
      @comment_payload = document.highlight_comments
      respond_to do |format|
        format.turbo_stream { render :create, status: :unprocessable_entity }
      end
    end
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
- Both success and failure rebuild `@comment_payload` and render the same Turbo Stream template — uniform contract, no redirect anywhere.
- On 422, the source is replaced with unchanged content (so marks don't drift) and an inline error element is populated; the textarea value is preserved by the browser (Turbo Stream only touches the targeted element).
- `application_controller` default `respond_to` blocks pick up `format.turbo_stream` because Turbo submits with `Accept: text/vnd.turbo-stream.html`. No route change (`POST /documents/:document_id/comments` stays as-is in `config/routes.rb:19`).

### 2. Turbo Stream view — `app/views/comments/create.turbo_stream.erb` (new file/dir)
The project's first Turbo Stream view. `app/views/comments/` does not exist yet — this step creates it.

```erb
<%= turbo_stream.replace "comment_payload_source" do %>
  <script type="application/json" id="comment_payload_source"
          data-comment-highlight-target="source">
    <%= @comment_payload.to_json.html_safe %>
  </script>
<% end %>

<% if @create_error.present? %>
  <%= turbo_stream.update "comment_create_error", @create_error %>
<% else %>
  <%= turbo_stream.update "comment_create_error", "" %>
  <%= turbo_stream.action :reset_create_form, "document_paper" %>
<% end %>

<%= turbo_stream.action :reload_comments, "document_paper" %>
```
- `turbo_stream.replace` swaps the JSON source `<script>` (must keep the same `id="comment_payload_source"` so the replace targets the existing node).
- `reload_comments` is a **custom** Turbo Stream action (registered in step 4) that dispatches a `comment-highlight:reload` event on `#document_paper`; the highlight controller listens for it and re-applies highlights from the freshly-replaced source.
- `reset_create_form` is a second custom action dispatching `comment-create:reset`, which `text_selection_controller#hideButton` already handles — collapses the create card and clears the transient selection highlight. (If the user prefers fewer custom actions, an alternative is to add a `turbo:submit-end` listener on the form that calls `hideButton()` when the response is 2xx; this plan uses the custom action for symmetry with the editionalso taken in `plans/edit-existing-comment.md` and to keep the trigger explicit/decoupled from form lifecycle.)

### 3. View — `app/views/documents/show.html.erb`
Three small edits:

3a. Give `.document__paper` a stable `id` + wire custom-event listeners (so the dispatched events reach the right controllers):
```erb
<div class="document__paper" id="document_paper"
     data-controller="text-selection comment-highlight comment-copy"
     data-action="comment-highlight:reload->comment-highlight#reloadFromSource
                  comment-create:reset->text-selection#hideButton">
```

3b. Give the JSON `<script>` a stable `id` so `turbo_stream.replace "comment_payload_source"` can target it:
```erb
<script type="application/json" id="comment_payload_source"
        data-comment-highlight-target="source"
        data-comment-copy-target="source">
  <%= @comment_payload.to_json.html_safe %>
</script>
```
(The existing `data-comment-highlight-target="source"` and `data-comment-copy-target="source"` are preserved.)

3c. Add an error element inside `.document__comment-card` (right after the textarea, before `.document__comment-actions`) so Turbo Stream can target `#comment_create_error`:
```erb
<p class="document__comment-create-error" id="comment_create_error"></p>
```
No other view changes — the create form itself stays inline in `show.html.erb` (extracting to a partial is part of the larger `edit-existing-comment.md` plan; not needed for create-only).

### 4. Custom Turbo Stream actions — new module + importmap pin
`application.js` should stay a thin entry point (just imports), not hold registration logic. Put the stream actions in their own module and pin it via the importmap.

**4a. New file `app/javascript/turbo_stream_actions.js`**
```js
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
- The dispatched events bubble up from `#document_paper` (the targeted element), which is the controller root for both `text-selection` and `comment-highlight` — so the `data-action="..."` mappings added in 3a fire.
- `this.targetElements` resolves the `<turbo-stream target="document_paper">` target attribute to the matching DOM node.
- Importing `@hotwired/turbo-rails` here gives access to the `Turbo` global without re-bundling (importmap dedolves modules); `application.js` still imports it as the entry that actually boots Turbo.

**4b. `config/importmap.rb` — pin the new file**
```ruby
pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/utils", under: "utils"
pin "turbo_stream_actions", to: "turbo_stream_actions.js"
```
(The `pin "application"` entry already exists at line 3. Only the new `pin "turbo_stream_actions", ...` line is added.)

**4c. `app/javascript/application.js` — import the new module (no logic added)**
```js
// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "turbo_stream_actions"
import "controllers"
```
- One added import line; `application.js` stays a pure entry point — boot order is: Turbo → register stream actions → boot Stimulus controllers. Registration must happen before any Turbo Stream response is processed (it does: imports run before the first navigation triggers a stream).

### 5. JS — `app/javascript/controllers/comment_highlight_controller.js`
Two additions:

5a. Idempotent reload: re-applying highlights requires unwrapping existing marks first, otherwise stale marks from before the create linger.
```js
clearAllMarks() {
  this.allMarks.forEach(mark =>
    mark.replaceWith(document.createTextNode(mark.textContent))
  )
  this.allMarks = []
  this.contentEl.normalize()
}
```
Call `this.clearAllMarks()` at the start of `loadComments()` (before `this.applyAllComments()`). First `connect()` call: `this.allMarks` is `[]` → no-op + harmless `normalize()`.

5b. The reload handler wired in 3a:
```js
reloadFromSource() {
  this.loadComments()
}
```
For create-only scope, no popover re-anchoring is needed (no popover is open during create). If the popover happens to be open from a previously-clicked comment, the open popover's marks are unwrapped + re-wrapped; the popover keeps showing stale `currentComment` text — acceptable for the create case (the user was creating a new comment, not editing). If we want polish, copy the `reloadFromSource` re-anchor logic from `plans/edit-existing-comment.md` step 8.

### 6. CSS — `app/assets/stylesheets/pages/document.css`
Add a small rule for the inline error (the create card now has it):
```css
.document__comment-create-error {
  margin: 0;
  font-size: 0.75rem;
  color: #dc2626;
}

.document__comment-create-error:empty {
  display: none;
}
```
The error is only visible when populated; `:empty` keeps layout clean otherwise.

### 7. Tests — `test/integration/comments_test.rb`
Update the existing test to assert a Turbo Stream response instead of a redirect:
```ruby
test "creates a comment via turbo stream" do
  file = Tempfile.new(["sample", ".md"])
  file.write("# Hello world")
  file.close

  document = Document.create!(file_path: File.realpath(file.path), version: "1")

  assert_difference("Comment.count", +1) do
    post document_comments_path(document),
         params: { content: "A comment", start_block_id: "block-1",
                   end_block_id: "block-1", start_offset: 3, end_offset: 8,
                   selected_text: "Hello", prefix_text: "# ", postfix_text: " world" },
         as: :turbo_stream
  end

  assert_response :ok
  assert_match %r{turbo-stream}, response.content_type
  assert_match "A comment", response.body   # payload includes the new comment
  comment = document.comments.last
  assert_equal "A comment", comment.content
  assert_equal 3, comment.start_offset
ensure
  file.unlink
end

test "create with blank content renders 422 turbo stream" do
  document = ...
  post document_comments_path(document), params: { content: "" }, as: :turbo_stream
  assert_response :unprocessable_entity
  assert_match "Content", response.body   # validation error rendered inline
end
```
Note the existing test uses `Document.open(file.path)` indirectly by visiting the page first; for a Turbo Stream test we can construct the `Document` row directly (or keep the `get open_documents_path` step then post — both work). Use whichever matches the codebase's `Document.open` conventions.

## Risks / Open questions
- **Custom actions vs. `turbo:submit-end`**: this plan introduces two custom Turbo Stream actions (`reload_comments`, `reset_create_form`). An alternative with zero custom actions: keep only the `turbo_stream.replace` of the source, and add a `turbo:submit-end` listener on the form in `text_selection_controller` that calls `hideButton()` when `event.detail.success`. Trade-off: tighter coupling to form lifecycle, but fewer moving parts. Pick one — the plan currently uses custom actions for symmetry with `edit-existing-comment.md`.
- **Popover stale during create**: if a user has a comment popover open and then creates a *different* comment, the popover keeps showing the old `currentComment` content (whose marks were unwrapped + re-wrapped, so visually the highlight is fine but `currentMark` now points to a detached old mark). Acceptable for create-only; if not, port the re-anchor logic from `plans/edit-existing-comment.md` step 8's `reloadFromSource`.
- **Source `<script>` replace ordering**: `turbo_stream.replace` of the source must run *before* `reload_comments`, otherwise the controller re-parses the *old* JSON. Turbo Stream actions in a template execute in document order — the template in step 2 puts `replace` first. Verified by the Turbo spec.
- **Stimulus target lookup after replace**: `comment-highlight-target="source"` is regenerated by the `turbo_stream.replace`, but the controller instance is the same; Stimulus re-resolves targets lazily via `this.sourceTarget` — and `reloadFromSource` reads `this.sourceTarget.textContent` *after* the swap, so it sees the new JSON. Confirmed by Stimulus target semantics.
- **Existing integration test**: step 7 deliberately changes the assertion from `assert_redirected_to` — this is an intentional contract change, not a regression.
- **No JS lint configured** in the project — `bin/rubocop` covers Ruby only.

## Verification
- `bin/rubocop` — Ruby styling.
- `bin/rails test` — updates the create integration test (step 7) plus the new 422 test.
- Manual via `bin/rails dev`:
  1. Open a markdown document, select text, click **Add Note**, type, click **Comment**.
  2. Network tab: only one `POST /documents/:id/comments`, `Accept: text/vnd.turbo-stream.html`, response `Content-Type: text/vnd.turbo-stream-html`, **no follow-up GET to the document**, **no flash**, **scroll position preserved**.
  3. New persisted amber highlight appears at the selected range; the create card collapses; the transient selection highlight is gone.
  4. Nav count increments to include the new comment.
  5. Click the new highlight → popover shows the just-typed content + creation date.
  6. Submit empty content → 422 returned; `#comment_create_error` shows "Content can't be blank"; textarea retains focus and value; no DB row added; existing highlights untouched.
  7. Reload the page → the new comment persists; `@comment_payload` reflects DB state.