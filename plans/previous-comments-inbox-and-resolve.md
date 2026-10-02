# Previous comments inbox + document versions

## Goal
Surface comments made on past document versions (whose block anchors no longer exist after a markdown re-parse) in a dedicated "Previous comments" section at the bottom of the document view, navigable via a floating inbox button, and let the user mark each as `is_resolved` (dimmed but still visible). At the same time, restructure block storage so blocks belong to a per-version record (`document_versions`) to make per-version history scalable in the future.

The implementation is split into **two phases** that ship as separate commits:

- **Phase 1 — Schema restructure**: introduce `document_versions`, repoint `document_nodes` and `comments` to it, backfill existing data, and refactor `AstParseable` to create a new version record on each re-parse (keeping only the latest version's blocks — old version records are kept as reference but their blocks are dropped, exactly as today's delete-all behavior). **Committed first.**
- **Phase 2 — Old comments UI**: split the comment payload into current vs. archived, add the bottom "Previous comments" section, the floating inbox button, and the `is_resolved` toggle.

---

## Phase 1 — Schema restructure

### 1.1 Generate `document_versions` table
- Run `bin/rails g migration CreateDocumentVersions` (do not hand-create the migration file).
- Migration creates:
  - `id` (int PK)
  - `document_id` (FK → documents, indexed, NOT NULL)
  - `version` (string, NOT NULL) — e.g. `"v1"`, `"v2"`
  - `size` (integer), `last_modified_at` (datetime) — snapshot metadata
  - `created_at` / `updated_at`
  - unique index on `(document_id, version)`
- **Do NOT snapshot `content`** per version (per feedback): old version records are kept only as reference for comment anchoring metadata; their blocks are not preserved. Unbounded content growth isn't a concern because we only store version metadata, not content blobs.
- Add `DocumentVersion` model (`app/models/document_version.rb`):
  - `belongs_to :document`
  - `has_many :document_nodes, dependent: :destroy`
  - `has_many :comments, dependent: :destroy`

### 1.2 Repoint `document_nodes` to `document_versions`
- Run `bin/rails g migration RepointDocumentNodesToDocumentVersions` — **separate migration file** from 1.1.
- On `document_nodes`: rename `document_id` → `document_version_id`, update the FK to point at `document_versions`, reindex. (Data backfill of the new FK values happens in migration 1.3, not here — this migration only changes the column/FK shape.)

### 1.3 Backfill data
- Run `bin/rails g migration BackfillDocumentVersionsForExistingDocuments` — **separate data migration**.
- For each existing `Document`:
  - Create one `DocumentVersion` row from the document's current `version`, `size`, `last_modified_at`.
  - Repoint that document's `document_nodes.document_version_id` to the new version's id.
  - (Comments get their `document_version_id` in migration 2.1 alongside adding the columns.)

### 1.4 Add `document_version_id` + `is_resolved` to `comments`
- Run `bin/rails g migration AddVersionAndResolvedToComments` — **separate migration file**.
- Add:
  - `document_version_id` (int, FK → document_versions, indexed, NOT NULL) — **kept alongside** the existing `document_id` (both FKs present; `document_id` stays denormalized for convenience and clean cascading deletes).
  - `is_resolved` (boolean, default false, NOT NULL)
- Validation in the `Comment` model ensures `document_version_id` belongs to the same `document_id` (consistency check).
- Backfill within this migration: set `document_version_id` to each comment's document's current (only) version, `is_resolved = false`.

### 1.5 Adjust `Document` associations + `AstParseable`
- `Document`:
  - `has_many :document_versions, dependent: :destroy`
  - `has_one :current_version, -> { order(created_at: :desc) }, class_name: "DocumentVersion"`
  - `has_many :document_nodes, through: :current_version` (read-only convenience for `DocumentsController#prepare_document`)
  - `has_many :comments, dependent: :destroy` (kept directly on `document_id` for simplicity; archived filtering goes through `document_versions`).
- `Documents::AstParseable` (concern for re-parse on open when `mtime`/`size` changed):
  - Instead of bumping `documents.version` in place, create a **new** `DocumentVersion` (next version label — derive the numeric suffix from the latest version of that document) with `size` / `last_modified_at`.
  - Destroy the **previous** version's `document_nodes` (keep the old version record + its comments intact → those comments become "old"). This matches today's delete-all-blocks behavior; we just no longer discard the version metadata.
  - New nodes are created under the new version's id.
  - Update `root_node_tree` / `next_version` to read off `current_version`.

### 1.6 Minitest (Phase 1, minimal)
- `DocumentVersion`: `current_version` returns the latest by `created_at` order.
- `Document`: after a re-parse, a new `DocumentVersion` exists; previous version's `document_nodes` are destroyed; previous version's `comments` remain attached to the old version record.
- `Comment`: `document_version_id` consistency validation rejects mismatched `document_id`.

**→ Commit Phase 1 before starting Phase 2.**

---

## Phase 2 — Old comments UI

### 2.1 Split comment payload: current vs. archived
- In `app/models/documents/highlightable.rb` (or a new concern `Documents::Commentable` if it grows), split the payload:
  - **`highlight_comments`** → only comments on `current_version`, serialized as today (anchored to current block ids, inline highlightable).
  - **`archived_comments`** → comments on `document_versions` other than `current_version`, serialized with: `id`, `content`, `selected_text`, `version` label, `created_at`, `is_resolved`.
- `#comment_payload_source` JSON becomes `{ current: [...], archived: [...] }` — both consumed by Stimulus.
- Update `CommentsController#set_comment_payload` to set both `@comment_payload` (current) and `@archived_comments` (archived), and turbo-stream partials (`create/update/destroy.turbo_stream.erb`) to re-render both sources.

### 2.2 Extend `CommentsController` with `toggle_resolved`
- Add route: `member { patch :toggle_resolved }` under nested comments.
- Single `toggle_resolved` action flips `is_resolved` and re-renders the archived section + payload. Label/state flips in the button UI.
- Server-side guard: reject (422) if the comment is on the current version — resolve is only meaningful for archived comments.
- `comment_params` unchanged (`is_resolved` not settable via the create/edit form).

### 2.3 View: "Previous comments" section
- New partial `app/views/comments/_archived.html.erb` rendered at the bottom of `show.html.erb`, after `.document__content`:
  - Section heading "Previous comments" + count, anchored with `id="previous-comments"`.
  - Iterate `@archived_comments` ordered by version desc, then `created_at` asc within version.
  - Each entry (BEM `document__archived-comment`, with `--resolved` modifier when `is_resolved`):
    - Per feedback format — selected text in **quote style**, comment as **normal text**:
      ```
      > "selected_text"

      content
      ```
    - Meta line: creation date + version label (`v2`).
    - Resolve check button → PATCH `toggle_resolved_document_comment_path(@document, comment)`; for resolved comments, button becomes "Undo" + "Resolved" tag.
- Use turbo-stream replacement of the section partial (matches the existing refresh pattern); no separate JS controller needed.

### 2.4 View: floating inbox button
- Add a second floating button inside `.document__comment-nav` (right rail) in `show.html.erb`, after the copy divider:
  - Inbox icon, BEM class `document__comment-inbox-button`.
  - On click → `document.getElementById("previous-comments").scrollIntoView({ behavior: "smooth" })` (tiny Stimulus action on a generic scroll-anchor controller, or an inline data-action).
  - **Badge with archived count** on the icon (e.g. `"3"`).
  - Show button only when `@archived_comments` non-empty (server-render conditionally).
- Tweak the rail visibility logic in `comment_highlight` `loadComments`: keep the rail (or at least the inbox button) visible when there are archived comments even if zero current comments.

### 2.5 Resolve interactions on UI
- Inline current comments keep existing popover UI — **no** resolve button (per requirement).
- Old comments list: check button → PATCH `toggle_resolved` → turbo-stream re-renders the section with the comment dimmed (`--resolved` modifier: greyed text, strikethrough on selected text, "Resolved" tag) and an undo toggle.

### 2.6 Stimulus adjustments (minimal)
- `comment_highlight_controller`: read `JSON.parse(...).current` instead of the raw array.
- `comment_copy_controller`: same — copy only `current` comments.
- `comment_popover_controller`: unaffected (popover only used for current/inline comments).

### 2.7 CSS
- In `pages/document.css`, extend `document__comment-*` BEM:
  - `.document__archived`, `.document__archived-title`, `.document__archived-list`, `.document__archived-comment`, `.document__archived-comment--resolved`, `.document__archived-comment-quote`, `.document__archived-comment-body`, `.document__archived-comment-meta`, `.document__archived-comment-resolve`, `.document__archived-comment-badge`.
  - `.document__comment-inbox-button` mirroring the rail button visuals, with a `.document__comment-inbox-badge` count bubble.
- Keep all in `pages/document.css` (document-page scoped).

### 2.8 Minitest (Phase 2, minimal)
- `Document#archived_comments` returns only non-current-version comments.
- `toggle_resolved` action: flips `is_resolved`, re-renders archived section; 422 when called on a current-version comment.
- Controller payload includes both `current` and `archived` keys with the right membership.

---

## Risks / Open questions
- **Version label generation** — `AstParseable` currently bumps `documents.version` string in place. With `DocumentVersion.version`, derive the next label from the latest version of that document by parsing the `vN` numeric suffix. Must handle existing `v1`, `v2` strings consistently — derive in Ruby, no numeric column.
- **Inbox button placement** — inside the existing `.document__comment-nav` rail (stacks below copy) for visual consistency; the rail currently auto-hides when no current comments, so the visibility tweak in 2.4 is required to keep the inbox button alone visible when only archived comments exist.
- **Old comment definition edge case** — a comment made on the current version whose block was re-edited in place but the block id coincidentally still exists. Out of scope per feedback — version-based definition is sufficient.
- **Old blocks storage** — per feedback, we don't keep blocks of previous versions; old `document_versions` rows remain only as reference metadata for comment anchoring. No content snapshot per version.