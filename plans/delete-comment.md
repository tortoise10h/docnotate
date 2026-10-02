# Delete comment

## Goal

Let users remove a comment they no longer need. Deleting a comment should remove its database record, unwrap the associated text highlight, and update the comment navigation / copy UI — all without a full page reload.

## Context

- Comments are stored in `app/models/comment.rb` and belong to `Document` (`has_many :comments, dependent: :destroy`).
- `CommentsController` (`app/controllers/comments_controller.rb`) currently only implements `create`.
- Comments are rendered as JSON via `Documents::Highlightable#highlight_comments` (`app/models/documents/highlightable.rb`) and embedded in `app/views/documents/show.html.erb` inside `<script id="comment_payload_source">`.
- The highlight popover is rendered in `app/views/documents/show.html.erb` and populated by `comment_highlight_controller.js` (`app/javascript/controllers/comment_highlight_controller.js`).
- The create flow uses Turbo Streams: `app/views/comments/create.turbo_stream.erb` replaces the JSON source and dispatches custom stream actions `reload_comments` / `reset_create_form` defined in `app/javascript/turbo_stream_actions.js`.
- The existing custom stream action `reload_comments` already re-applies highlights and refreshes the copy button, so it can be reused for delete.

## Plan

1. **Expose the destroy route**
   - Update `config/routes.rb` to add `:destroy` to the nested `comments` resource (`resources :comments, only: [:create, :destroy]`).

2. **Add `CommentsController#destroy`**
   - Find the comment under the current document, destroy it, then set `@comment_payload = @document.highlight_comments`.
   - Render `destroy` with Turbo Stream format.
   - On failure, render a 422 Turbo Stream with a short error message (unlikely for a hard delete, but keeps the controller honest).

3. **Create `app/views/comments/destroy.turbo_stream.erb`**
   - Replace `comment_payload_source` with the fresh `@comment_payload` JSON.
   - Dispatch a new custom Turbo Stream action `hide_popover` on `#document_paper` so the open popover closes immediately.
   - Dispatch the existing `reload_comments` custom action on `#document_paper` so highlights, navigation count, and copy button refresh from the new payload.

4. **Register `hide_popover` custom Turbo Stream action**
   - Add `Turbo.StreamActions.hide_popover` in `app/javascript/turbo_stream_actions.js` that dispatches `comment-highlight:hide-popover` on the target element.
   - Wire the event in `comment_highlight_controller.js` to call the existing `hidePopover()` method.

5. **Add a delete button to the comment popover**
   - In `app/views/documents/show.html.erb`, add a trash icon button inside `.document__comment-popover-header`, next to the existing close button.
   - Place the button inside a small Rails delete form (`form_with ..., method: :delete`) so Turbo handles the submission naturally. Store the form as a Stimulus target and update its action dynamically when a comment is shown.

6. **Wire the popover delete form in `comment_highlight_controller.js`**
   - Add `deleteForm` (and optionally `popoverDelete`) to `static targets`.
   - Read the document id from a data attribute on `#document_paper`.
   - In `showPopover`, update the delete form action to `/documents/:document_id/comments/:comment_id` for the currently displayed comment.
   - Listen for `comment-highlight:hide-popover` and call `hidePopover()`.

7. **Style the delete button**
   - Add CSS in `app/assets/stylesheets/pages/document.css` for the popover header delete button, keeping it visually distinct from the close button and aligned with the existing popover header style.

8. **Add integration test**
   - In `test/integration/comments_test.rb`, add a test that creates a comment, issues a Turbo Stream DELETE to `document_comment_path(document, comment)`, asserts `Comment.count` decreases by 1, and verifies the response contains the updated payload without the deleted comment.

## Risks / Open questions

- **Popover closes after delete even if the user wanted to keep browsing nearby comments.** Acceptable because the deleted comment no longer exists; the nav arrows remain available to move to the next/previous comment.
- **Race condition: comment deleted between popover open and click.** The controller will render a 422; the UI will keep the popover open but show an error. We should keep the error path minimal.
- **Hard delete is irreversible.** Confirmed with the user; matches the existing `dependent: :destroy` association.
- **Form action updated in JS uses a hand-built URL.** The route is a standard Rails nested resource (`/documents/:id/comments/:id`), so the path is stable. If routing changes later, this JS must be updated too.
