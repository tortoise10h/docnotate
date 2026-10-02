# Document Table of Contents (left panel)

## Goal

Add a table of contents to the document view (`app/views/documents/show.html.erb`) so readers of long documents can jump between headings. The TOC is a fixed vertical panel on the left of the page, styled to match the existing floating panels (comment nav, selection toolbar).

## Context

- Headings are already rendered as `h1`–`h6` in `app/views/documents/_document_node.html.erb`, each with a stable, DB-persisted `node_id` (generated in `app/models/markdown_parser.rb` with `block-<hex>` prefix and stored per document version).
- `Document#root_node_tree` (`app/models/documents/ast_parseable.rb`) returns the full ordered AST tree for the current version — headings and their text are already loaded in memory; no extra queries needed to build the TOC.
- Existing floating-panel precedent: `.document__comment-nav` is `position: fixed; right: 24px` with white bg, `1px solid #e5e7eb` border, `border-radius: 12px`, soft shadow. The TOC will mirror this visual language on the left side.
- Sticky header (`.document__header`) sits at `top: 0`; `scroll-margin-top` support already exists for `[id^="block-"]` anchors.
- Stimulus controllers live in `app/javascript/controllers/`; page styles live in `app/assets/stylesheets/pages/document.css`.
- Decisions confirmed: TOC includes **h1–h3 only**, rendered as a **fixed left panel** (hidden on narrow viewports, no layout change to the paper), with **scroll-spy** highlighting of the active section.

## Plan

### 1. Model: extract headings via a new concern

Create `app/models/documents/table_of_contents.rb`:

```ruby
module Documents
  module TableOfContents
    extend ActiveSupport::Concern

    TocEntry = Data.define(:id, :level, :text)

    def table_of_contents
      collect_headings(root_node_tree).map { |heading| ... }
    end
  end
end
```

- Include it in `Document` (keeps the model file thin, per the concerns convention, alongside `AstParseable`).
- Walk the ordered tree (same traversal order as rendering) and collect `node_type: "heading"` nodes with `heading_level` 1–3.
- Derive each entry's plain text by recursively flattening descendants down to leaf nodes that carry `content` (handles inline `code`, `strong`, `link`, etc. inside a heading).
- Return `TocEntry` records with `node_id` (anchor target), `heading_level`, and flattened text. Empty array when the document has no h1–h3 headings.
- Use `Data.define` structs (matches the existing `ParseMetadata = Data.define(...)` pattern in `AstParseable`).

### 2. Partial: TOC panel

Create `app/views/documents/_table_of_contents.html.erb` — a `<nav>` with:

- `data-controller="table-of-contents"` on the nav.
- One link per heading: `href="#<node_id>"`, `data-action="click->table-of-contents#select"`, `data-table-of-contents-target="link"`, plus the heading id as a data attribute for the scroll spy.
- Indentation applied via a level modifier class (`data-level` attribute + CSS), so `_table_of_contents.html.erb` stays minimal.
- Early return (render nothing) if the entry list is empty — summarizes into a guard in the partial.

Render it from `show.html.erb` as a sibling of `.document__paper` (fixed positioning makes placement within the `.document` wrapper harmless):

```erb
<%= render "table_of_contents", entries: @document.table_of_contents %>
```

### 3. Stimulus controller: `table_of_contents_controller.js`

Create `app/javascript/controllers/table_of_contents_controller.js`:

- **`select(event)`**: `preventDefault()`, plain JS smooth-scroll to the heading element (avoids the `:target` blue-flash styling in `document.css` and keeps the URL hash clean).
- **Scroll spy**: in `connect()`, resolve each link's target heading element and observe with `IntersectionObserver` (root margin top-biased so the heading nearest the top of the viewport wins). Toggle `--active` on the matching link and scroll the active entry into view within the panel when the list overflows.
- No verbose tuning initially — a simple "last heading above the fold is active" heuristic.

### 4. CSS: add to `app/assets/stylesheets/pages/document.css`

Follow the existing BEM + floating-panel language:

- `.document__toc`: `position: fixed`, `top` below the sticky header (~`88px`), `left: max(24px, calc(50% - 450px - 268px))` (24px gap to the paper's left edge, 244px panel width), `max-height: calc(100vh - 112px)`, `overflow-y: auto`, white background, `1px solid #e5e7eb` border, `border-radius: 12px`, same box-shadow as `.document__comment-nav`, subtle scrollbar styling.
- `.document__toc-list`: simple `<ul>` reset, small column gap.
- `.document__toc-item`: link row, `font-size: 0.8125rem`, `color: #4b5563`, `border-radius: 6px`, hover background `#f3f4f6` (same as comment's nav buttons), truncated single-line text via `white-space: nowrap; overflow: hidden; text-overflow: ellipsis`.
- `.document__toc-item--level-2 / --level-3`: `padding-left` indentation (e.g. 0 / 12px / 24px).
- `.document__toc-item--active`: `color: #1d1d1f; background: #f3f4f6; font-weight: 500`.
- Responsive: media query shows the panel only at `>= 1400px` viewport width (below that it would collide with the 900px paper). Hidden Usage otherwise; no drawer/toggle.

### 5. Tests

Add focused cases to `test/models/document_test.rb` (or a new `test/models/documents/table_of_contents_test.rb` if cleaner):

- Extracts h1–h3 headings in document order with correct ids, levels, and flattened text (including a heading with inline code/strong).
- Skips headings deeper than h3.
- Returns `[]` for a document without headings.

No controller/integration test needed — rendering is a plain partial include, verified manually.

## Risks / Open questions

- **Viewport cutoff**: The TOC is invisible on viewports narrower than ~1400px. If you typically read in a narrower window we can lower the panel width/paper gap or add a later collapsible toggle — kept out of scope for now to stay minimal.
- **Node text flattening**: Heading text is derived by walking children; edge mixing (e.g. images inside headings) will just contribute nothing. Acceptable for a TOC.
- **Scroll-spy on long code blocks**: With a huge code block spanning a viewport, the observer may briefly keep the previous heading active. The simple top-biased heuristic handles it reasonably; we can tune root margin if it feels off.
- Random ids: `node_id` is `SecureRandom`-based at fresh parse time but persisted afterwards per version, so anchors stay stable between page loads of the same document version.
