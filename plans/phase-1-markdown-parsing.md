# Phase 1: Markdown Parsing & Rendering

## Overview
Implement the first core feature: open a markdown file, parse it to an AST using the `commonmarker` gem, assign unique block IDs for DOM identification, cache the parsed AST nodes in a relational table for faster re-access, and render it in a read-only view using custom logic (not pre-baked HTML).

---

## 1. Database Layer ✅

### `documents` table
- `file_path` (string, not null, **unique**) — **absolute path** to the markdown file on disk
- `file_type` (string, not null) — file type / format identifier (e.g., `markdown`, `asciidoc`, `textile`) to support multiple formats in the future
- `content` (text, not null) — raw markdown text read from the file
- `version` (string, not null) — simple short version string (e.g., `v1`, `v2`, `v3`) to track updates when the same file is reopened after changes
- timestamps

### `document_nodes` table
- `document_id` (bigint, not null, foreign key → documents)
- `node_type` (string, not null) — CommonMarker node type (e.g., `document`, `paragraph`, `heading`, `text`, `strong`, `emph`, `code`, `code_block`, `list`, `list_item`, `link`, `image`, `blockquote`, `thematic_break`, `softbreak`, `linebreak`)
- `content` (text) — text content for leaf/text nodes; `NULL` for container nodes
- `node_id` (string) — unique HTML element ID assigned to block-level nodes (e.g., `block-1`, `block-2`); `NULL` for inline/container nodes
- `parent_id` (bigint, foreign key → document_nodes) — self-referential link to build the tree hierarchy; `NULL` for root document node
- `position` (integer, not null) — zero-based sort order among siblings under the same parent
- `heading_level` (integer) — heading level `1`–`6`; `NULL` for non-heading nodes
- `meta` (json) — extra node-specific attributes (e.g., `{"language":"ruby"}` for fenced code blocks, `{"url":"..."}` for links, `{"list_type":"ordered","tight":true}` for lists)
- timestamps

---

## 2. Model Layer  ✅

**Done:**
- `CommonMarker` AST parsing via `MarkdownParser` PORO
- Recursive AST walk creates `DocumentNode` records
- Unique block IDs assigned to block-level nodes with `SecureRandom`
- `DocumentNode.root_node_tree` loads the tree
- `DocumentNode.tree_for` + `build_tree` builds tree in-memory with `children` association preloaded (N+1-free)
- `DocumentNode` associations (`belongs_to :document`, self-referential parent/children, `ordered` scope)

### `Document` model
- Use `CommonMarker` to parse `content` into an AST. ✅
- Walk the AST tree and create corresponding `DocumentNode` records. ✅
- Assign sequential unique IDs (e.g., `id="block-1"`, `block-2"`, …) to every **block-level** node. ✅
- Provide a method to load the root `DocumentNode` tree for rendering. ✅
- `next_version` — instance method to increment version string (`v1` → `v2`). ✅
- `file_type_from_path` — class method to determine file type from extension. ✅
- **Note:** No service objects. All logic lives in the model layer, per project conventions.

### `DocumentNode` model
- Belongs to `document`. ✅
- Self-referential `belongs_to :parent, class_name: "DocumentNode"` and `has_many :children, class_name: "DocumentNode", foreign_key: "parent_id"`. ✅
- Scope to order by `position`. ✅
- Preload children efficiently (e.g., `eager_load` or custom tree builder) when rendering. ✅

---

## 3. Controller Layer ✅
- Create `DocumentsController`:
  - `create`: Accept `file_path` parameter (local file path, not upload), read content from disk, find or create a `Document` by `file_path`, set/increment `version`, overwrite `content`, call `document.parse_ast_and_save!`, then redirect to `show`.
  - `show`: Load the document and its AST tree via `document.root_node_tree`, pass to the view.
- Keep controllers thin — all logic delegated to model layer (`Document.next_version`, `Document.file_type_from_path`).

---

## 4. Routes ✅
- Add `resources :documents, only: [:create, :show]` to `config/routes.rb`.

---

## 5. View Layer ❌
- Update `home/index.html.erb`: Wrap the drop zone in a form that POSTs the selected file to `documents_path`.
- Create `documents/show.html.erb`: Render the markdown by recursively walking the AST tree and emitting custom HTML.
- Split into partials if needed (e.g., `_document_node.html.erb`, `_document_content.html.erb`) to keep the main view file short and readable.

---

## 6. Styles ❌
- Create `app/assets/stylesheets/pages/document.css` for markdown-specific rendering (headings, code blocks, lists, blockquotes, etc.).
- Import it in `application.css`.
- Follow the existing BEM naming convention.

---

## 7. JavaScript ⚠️ Partial
- Update `drop_zone_controller.js` to work with the form submission (auto-submit on file selection via the `change` event).

---

## 8. Tests ❌
- Add model tests for `Document` AST parsing, ID assignment, and `DocumentNode` tree creation.
- Add model tests for `DocumentNode` associations and ordering.
- Add controller/integration tests for the file upload and document show flow.

---

## Decisions to Confirm
1. **Block ID Granularity:** Every block-level element gets an ID. Inline elements inside a block are not individually ID'd for this phase.
2. **Storage Strategy:** Store AST nodes in a normalized relational table (`document_nodes`) instead of a single JSON column. This allows efficient querying, tree traversal, and future extension (e.g., mapping comments to specific blocks).
3. **Upload UX:** Auto-submit on file selection (drag-and-drop or browse). No explicit "Open File" button.
4. **Versioning:** If the same `file_path` is opened again after the file changes, update the existing `Document` record (increment its version string, overwrite `content`, and rebuild the `DocumentNode` tree). The unique constraint on `file_path` guarantees only one active record per file.
