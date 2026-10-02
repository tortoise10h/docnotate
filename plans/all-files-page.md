# All-files page with pagination, rename, and delete

## Goal

Add a "zoom out" icon next to the **Recent files** header on the home page. Clicking it opens a new `/documents` index page that lists every file we have (paginated), where each file can be renamed (a display name only — the physical file is never touched) or removed from the app's history (the DB record only — the physical file is left on disk).

## Context

- Recent files are rendered on the home page in `app/views/home/index.html.erb`, loaded by `HomeController#index` (`app/controllers/home_controller.rb`) as the latest 5 documents ordered by `last_opened_at desc`.
- Documents have **no name field today** — the display name is always `File.basename(file_path)` (`app/views/home/index.html.erb`, `app/views/documents/show.html.erb`). `file_path` is the real on-disk path and is the unique canonical key (`db/schema.rb` `documents.file_path`, unique index).
- `Document` cascades deletes through existing `dependent: :destroy` associations: `document_versions` (`app/models/document.rb`), and from there `document_nodes` and `comments` (`app/models/document_version.rb`). Destroying a `Document` therefore removes its versions, nodes, and comments.
- Routes currently expose `resources :documents, only: [:show]` plus `collection { get :open }` (`config/routes.rb`).
- `DocumentsController` currently has only `open` and `show` (`app/controllers/documents_controller.rb`).
- The UI is Hotwire/ERB with pure CSS (BEM) split into foundation/components/pages, imported only via `app/assets/stylesheets/application.css`. Small Stimulus controllers live in `app/javascript/controllers/`.
- No pagination gem is present in `Gemfile.lock`.

## Plan

1. **Add a `name` column to documents**
   - `bin/rails g migration AddNameToDocuments name:string`
   - Keep it nullable: a blank `name` means "fall back to the file's basename".
   - Run `bin/rails db:migrate`.

2. **Add `Document#display_name` (and keep `file_path` canonical)**
   - Add to `app/models/document.rb`:
     `def display_name = name.presence || File.basename(file_path)`
   - `file_path` stays untouched by rename; it remains the key used to open files and look them up. Renaming only writes `name`.

3. **Add and configure Pagy**
   - Add `gem "pagy", "~> 9.0"` to `Gemfile` and run `bundle install`.
   - Create `config/initializers/pagy.rb` with `Pagy::DEFAULT[:items] = 20`.
   - Include `Pagy::Backend` in `ApplicationController` and `Pagy::Frontend` in `ApplicationHelper` (`app/controllers/application_controller.rb`, `app/helpers/application_helper.rb`).

4. **Expose the routes**
   - Change `config/routes.rb` from `resources :documents, only: [:show]` to `resources :documents, only: [:index, :show, :update, :destroy]`, keeping the existing `collection { get :open }` unchanged.

5. **Implement `DocumentsController` actions**
   - `index`: load all documents and paginate:
     `@pagy, @documents = pagy(Document.order(last_opened_at: :desc), items: 20)`.
     Every document is an "opened file" by construction (`Document.open` always sets `last_opened_at`), so no `last_opened_at IS NOT NULL` filter is needed.
   - `update`: `@document = Document.find(params[:id])`; `@document.update(name: params[:document][:name])`; redirect back to `documents_path` with a success/error flash.
   - `destroy`: `@document = Document.find(params[:id])`; `@document.destroy!`; redirect to `documents_path` with `notice: "Removed from history"`. Rescue `ActiveRecord::RecordNotDestroyed` → `alert`.

6. **Build the index view**
   - Create `app/views/documents/index.html.erb` with:
     - A header row: title "All files" and a "Home" link back to `root_path`, mirroring the `document__header` style in `app/views/documents/show.html.erb`.
     - A paginated list of files (one partial per row).
     - Pagy nav rendered with `<%== pagy_nav(@pagy) %>` below the list.
     - An empty state reusing `.empty-state` (no files at all).
   - Create `app/views/documents/_document_row.html.erb` showing, per document:
     - Display name via `document.display_name` (not `File.basename`), with the existing `data-tooltip` pattern to show full `file_path` on hover.
     - Last opened relative time (`time_ago_in_words`).
     - An "Open" link to `open_documents_path(file_path: document.file_path)`.
     - A **rename** affordance (inline form) and a **delete** affordance.

7. **Rename UX (display name only)**
   - Rename as a small inline form per row: a text input prefilled with `document.display_name`, with Save/Cancel.
   - Use a minimal Stimulus controller (e.g. `app/javascript/controllers/rename_row_controller.js`, following the existing controllers) to toggle between the display state and the edit state. Submitting the form does a full-page `PATCH` to `document_path` and redirects back to `documents_path` (keeps it simple and matches the delete flow).
   - Deleting uses `button_to document_path(document), method: :delete` with `data: { turbo_confirm: "Are you sure?" }`.

8. **Wire the home page "zoom out" icon**
   - In `app/views/home/index.html.erb`, wrap the `Recent files` header in a flex header row and add an icon-only link to `documents_path` (a "zoom out" / expand icon), with an `aria-label` and tooltip. Show it whenever the section renders.
   - Switch the recent-files name span to `document.display_name` so renamed files show their new name on the home page too.

9. **Show the renamed name on the document page**
   - In `app/views/documents/show.html.erb`, change the title from `File.basename(@document.file_path)` to `@document.display_name` (keep the `data-tooltip` on `file_path` so the real path stays visible).

10. **Style it to match the existing design**
    - Create `app/assets/stylesheets/pages/documents.css` for the index layout, the row list, the rename form, the delete button, and Pagy nav overrides.
    - Import it in `app/assets/stylesheets/application.css`.
    - Reuse the existing palette (`#1d1d1f`, `#6b7280`, `#9ca3af`, `#e5e7eb`, `#f3f4f6`), border radius, spacing, and tooltip pattern from `pages/home.css` / `pages/document.css`. Style Pagy nav to feel native (subtle borders, rounded buttons, active page in `#2563eb`).
    - Add a small home-page style for the new header row/icon in `pages/home.css`.

11. **Add tests**
    - In `test/integration/documents_test.rb` add (Minitest, concise):
      - `get documents_path` lists paginated documents.
      - Rename: `patch document_path(document), params: { document: { name: "New name" } }` updates `name` (not `file_path`) and redirects to `documents_path`.
      - Delete: `delete document_path(document)` destroys the record and redirects to `documents_path`.
      - Pagination splits the list when there are more than 20 documents.

## Risks / Open questions

- **Self-referential node cleanup on destroy.** `DocumentNode` has a self-referencing `parent_id` FK with `dependent: :destroy` on `children`. Destroying a Document cascades `document_versions` → `document_nodes`, which can delete a node more than once or hit the self-FK depending on deletion order. Exercise the destroy path in development with nested nodes before relying on it.
- **`name` uniqueness/validation.** `name` is purely cosmetic and should be allowed to be blank or duplicated (it's not a key), so no uniqueness validation. Confirm that's acceptable — two different files can share the same display name.
- **Sort order.** Index defaults to `last_opened_at desc`. If an alphabetical "file manager" feel is preferred, ordering by `display_name` (name-first, then basename) is a small follow-up; search/filter was intentionally left out of this pass.
- **Pagy default items.** 20 is a starting point; tune against how dense the row design feels.
