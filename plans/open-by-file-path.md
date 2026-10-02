# Plan: Open documents by local file path

## Goal

Replace the current file-upload / drop-zone flow on the home page with a single text input where the user types a local file path and presses Enter. Also support opening a document directly via URL, so an agent or user can use a link like `127.0.0.1:3535/documents/open?file_path=<local_file_path>`.

## Proposed URL format

Use a `GET` request to a custom collection action:

```
GET /documents/open?file_path=<local_file_path>
```

This follows the Rails convention of adding a non-CRUD collection action when the operation doesn’t fit the standard `index` / `create` / `show` verbs. It also keeps `index` available for its natural purpose (listing documents) and makes the action explicit. The home form and the agent-style URL will share the same endpoint.

## Files to change

### 1. `config/routes.rb`

- Keep `resources :documents, only: [:show]`.
- Change the existing collection route from `post :open` to `get :open`.

### 2. `app/controllers/documents_controller.rb`

- Keep the `open` action, but make it respond to `GET` instead of `POST`.
- In `open`:
  - Reads `params[:file_path]`.
  - Returns `redirect_to root_path, alert: "No file provided"` when the parameter is blank.
  - Calls `Document.open(file_path)` when the parameter is present.
  - Rescues `ArgumentError` / file system errors and redirects to `root_path` with an alert.
  - On success, redirects to `document_path(document)`.
- Simplify `resolve_file_path` to only consider `params[:file_path]`; remove the `params[:file]` branch.

### 3. `app/views/home/index.html.erb`

- Remove the drop-zone form, file input, and `multipart: true`.
- Replace it with a simple `GET` form to `open_documents_path` containing a single text field named `file_path`.
- Keep the recent files section unchanged.

Example:

```erb
<%= form_with url: open_documents_path, method: :get, class: "home__form" do |form| %>
  <%= form.text_field :file_path,
                      placeholder: "Enter local file path and press Enter",
                      class: "home__input",
                      autocomplete: "off" %>
<% end %>
```

### 4. CSS

- Remove the now-unused `app/assets/stylesheets/components/drop-zone.css`.
- Remove the now-unused `app/assets/stylesheets/components/file-input.css`.
- Remove their `@import` lines from `app/assets/stylesheets/application.css`.
- Add minimal styles for the new path input. This can live in `app/assets/stylesheets/pages/home.css` (e.g., `.home__form`, `.home__input`, `.home__hint`) or in a new component file.

### 5. JavaScript

- Delete `app/javascript/controllers/drop_zone_controller.js`. Rails Stimulus auto-loads controllers from `app/javascript/controllers`, so removing the file is sufficient.

### 6. Edge cases and security

- Blank `file_path`: redirect home with `alert: "No file provided"`.
- Missing / invalid file: rescue the `ArgumentError` from `Document.open` and redirect home with `alert: "File not found"` (or a similar message).
- Because the file path comes from user input (URL or form), the app can read any local file the server process has access to. This is acceptable for a local desktop app, but the controller should avoid exposing stack traces or raw Ruby errors to the user.

## Optional follow-ups

- Add a request test for `GET /documents/open?file_path=...` covering success and missing-file cases.
- Consider whether the home page should display an inline error instead of redirecting to root on failure.
