# Opened-files history page with pagination and delete

## Goal

Add a dedicated `/documents` index page that lists every opened file (not just the latest 5), paginates the results, and lets the user delete documents they no longer need from history.

## Context

- Recent files are currently shown on the home page (`app/views/home/index.html.erb`) via `HomeController#index`, which loads at most 5 documents ordered by `last_opened_at` desc (`app/controllers/home_controller.rb`).
- Documents are stored in the `documents` table with `file_path` (unique), `file_type`, `content`, and `last_opened_at` (`db/schema.rb`).
- `Document` already cascades deletes to `document_versions`, `document_nodes`, and `comments` through existing `dependent: :destroy` associations (`app/models/document.rb`, `app/models/document_version.rb`).
- Routes currently expose `resources :documents, only: [:show]` plus a `collection { get :open }` (`config/routes.rb`).
- The UI is Hotwire/ERB with pure CSS using BEM naming (`app/assets/stylesheets/pages/home.css`, `app/assets/stylesheets/components/`).
- Pagination will use the **Pagy** gem, deletes will **destroy the whole Document record**, the page will live at **`/documents`**, and pagination/delete will be **full page reloads** (per user preference).

## Plan

1. **Add and configure Pagy**
   - Add `gem "pagy", "~> 9.0"` to `Gemfile` and run `bundle install`.
   - Create `config/initializers/pagy.rb` with a sensible default such as `Pagy::DEFAULT[:items] = 20`.
   - Include `Pagy::Backend` in `ApplicationController` and `Pagy::Frontend` in `ApplicationHelper` so all controllers/views can use it.
   - Override Pagy's default nav markup in `app/assets/stylesheets/pages/documents.css` so pagination links use the project's colors, border radius, and hover states rather than Pagy's built-in styles.

2. **Expose `/documents` index route**
   - Change `config/routes.rb` from `resources :documents, only: [:show]` to `resources :documents, only: [:index, :show]`.
   - Add `destroy` later in step 5; keep the existing `collection { get :open }` unchanged.

3. **Implement `DocumentsController#index` with search**
   - Scope to opened documents: `Document.where.not(last_opened_at: nil).order(last_opened_at: :desc)`.
   - If `params[:q]` is present, filter the scope with a case-insensitive `LIKE` on `file_path`: `scope = scope.where("file_path LIKE ?", "%#{params[:q]}%")`.
   - Paginate with Pagy: `@pagy, @documents = pagy(scope, items: 20)`.
   - Render `app/views/documents/index.html.erb`.

4. **Build the index view**
   - Create `app/views/documents/index.html.erb` with:
      - A page header/title "Your opened files history" and a "Home" link back to `root_path`, mirroring the document show header style.
      - A search bar form (`GET` to `documents_path`) with a text field named `q`, placeholder "Search by file path", and a search button. Preserve the current query in the input.
      - A table or list of documents showing:
        - File name (`File.basename(document.file_path)`) with a tooltip showing the full `file_path` on hover (reuse the exact `data-tooltip` pattern from `app/views/home/index.html.erb`).
        - Last opened relative time (`time_ago_in_words(document.last_opened_at) + " ago"`)
        - An "Open" link to `open_documents_path(file_path: document.file_path)`
        - A delete button/form to remove the document
      - Pagy nav rendered with `<%== pagy_nav(@pagy) %>` below the list.
      - An empty state when no documents exist (including when a search returns no results).
    - Split reusable pieces into partials if needed per project view conventions (e.g., `app/views/documents/_document_row.html.erb`).

5. **Add document destroy action**
   - Update `config/routes.rb` to `resources :documents, only: [:index, :show, :destroy]`.
   - Add `DocumentsController#destroy`:
     - Find `Document.find(params[:id])`.
     - Call `destroy!` and redirect to `documents_path` with `notice: "File removed from history"`.
     - Rescue `ActiveRecord::RecordNotDestroyed` and redirect with `alert: "Could not remove file"`.
   - Use `button_to` with `method: :delete` and a confirmation (`data: { turbo_confirm: "Are you sure?" }`) in the index row.

6. **Style the new page to match existing design**
   - Create `app/assets/stylesheets/pages/documents.css` for the index page layout, row list, delete button, and Pagy nav overrides.
   - Import it in `app/assets/stylesheets/application.css`.
   - Keep styles consistent with `pages/home.css` and `pages/document.css`: reuse the existing color palette (`#1d1d1f`, `#6b7280`, `#9ca3af`, `#e5e7eb`, `#f3f4f6`), border radius, spacing scale, and tooltip pattern.
   - Style the Pagy nav so it feels native: subtle borders, rounded buttons, active page highlighted with the primary blue (`#2563eb`), and disabled/previous/next states matching the `.button` / `.button--secondary` components.

7. **Link the home page to the full list**
   - Add a "View all opened files" link in `app/views/home/index.html.erb` inside the `.home__recent` section, visible when `@recent_documents.any?`.

8. **Add tests**
   - In `test/integration/documents_test.rb` add:
      - A test that `get documents_path` returns the paginated list of opened documents.
      - A test that unopened documents are not listed.
      - A test that `get documents_path(q: "...")` filters results by `file_path` (case-insensitive partial match).
      - A test that `delete document_path(document)` destroys the document and redirects to `documents_path`.
      - A test that Pagy pagination splits the list when there are more than 20 opened documents.
    - Keep tests concise and follow the existing Minitest style.

## Risks / Open questions

- **Self-referential node cleanup on destroy.** `DocumentNode` has a `parent_id` foreign key to itself and `dependent: :destroy` on `children`. Destroying a Document triggers `document_versions` → `document_nodes` destruction, which may attempt to delete the same node twice or violate the self-FK depending on deletion order. We should run the destroy path in development with nested nodes before relying on it.
- **Pagy default items count.** 20 is a starting point; adjust based on how dense the row design feels.
- **SQL injection safety for search.** The plan uses a parameterized `LIKE` query (`"file_path LIKE ?"`), which is safe, but we should avoid string concatenation or `Arel.sql` when building the filter.
