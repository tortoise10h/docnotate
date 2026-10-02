# Add Markdown Table Rendering Support

## Goal
Render GitHub-Flavored Markdown tables in DocNotate so that `| ... |` syntax produces proper `<table>`, `<thead>`, `<tbody>`, `<th>`, and `<td>` markup, with each cell selectable and commentable the same way paragraphs and headings are.

## Context
- Markdown parsing lives in `app/models/markdown_parser.rb`, which walks the `Commonmarker.parse` AST and produces `DocumentNode` records.
- `BLOCK_LEVEL_TYPES` currently covers `paragraph heading code_block list item block_quote thematic_break`. Table-related AST nodes (`:table`, `:table_row`, `:table_cell`) are not recognized, so they fall through the renderer as invisible containers.
- Rendering is recursive ERB in `app/views/documents/_document_node.html.erb`; block-level nodes get `id="block-..."` which the JS uses via `BLOCK_SELECTOR = '[id^="block-"]'` for selection and comment highlighting.
- Styles are in `app/assets/stylesheets/pages/document.css` (BEM, Basecamp-style clean look).
- `app/models/documents/markdown_parseable.rb` has a separate stale `BLOCK_LEVEL_TYPES` constant and empty `parse_md_ast`/`build_nodes` methods; the real parser is `MarkdownParser`.
- Commonmarker 2.8.2 (already in the Gemfile) parses GFM tables. The AST exposes only `table`, `table_row`, and `table_cell`; alignment attributes are not available in the Ruby API.

## Plan

1. **Update `MarkdownParser` to recognize table nodes**
   - Add `:table`, `:table_row`, and `:table_cell` to `BLOCK_LEVEL_TYPES` so cells receive `block-*` IDs and become selectable/commentable.
   - Pass the parent AST node into `node_metadata` so table-cell metadata can know whether it sits in the header row.
   - Extend `node_metadata` with table-specific metadata:
     - `table_row`: `{"row_index" => position}`
     - `table_cell`: `{"is_header" => parent row position == 0, "cell_index" => position}`

2. **Update the document node renderer**
   - In `app/views/documents/_document_node.html.erb`, add cases for:
     - `table`: emit `<table>`, render the first child row inside `<thead>`, and remaining rows inside `<tbody>`.
     - `table_row`: emit `<tr>` and render children.
     - `table_cell`: emit `<th>` when `meta["is_header"]` is true, otherwise `<td>`, preserving `id="<%= node.node_id %>"` for selection.
   - Keep the recursive partial pattern; nested inline markup (bold, links, code) inside cells continues to work through the existing cases.

3. **Add table styles**
   - In `app/assets/stylesheets/pages/document.css`, add `.document-node--table`, `.document-node--table-row`, `.document-node--table-cell`, and `.document-node--table-cell-th` rules.
   - Style goals: full-width table, collapsed borders, consistent cell padding, distinct header background, and horizontal scroll for wide tables so the paper layout doesn't break.

4. **Keep the stale concern consistent**
   - Update the unused `BLOCK_LEVEL_TYPES` constant in `app/models/documents/markdown_parseable.rb` to include `:table`, `:table_row`, and `:table_cell`, or remove the module if it's truly dead. The plan assumes a minimal constant update so the two definitions don't drift further.

5. **Add tests**
   - Model-level test in `test/models/document_test.rb`: parse a document containing a table and assert that `DocumentNode` records exist for `table`, `table_row`, and `table_cell`, and that header cells have `meta["is_header"] == true`.
   - Integration test in `test/integration/documents_test.rb`: open a markdown file with a table and assert the response contains `<table>`, `<thead>`, `<tbody>`, `<th>`, and `<td>` elements with the expected text.

6. **Verify existing behavior**
   - Run the existing test suite (`bin/rails test`) to make sure the parser/renderer changes don't break paragraphs, headings, lists, code blocks, or comments.

## Risks / Open questions
- **Cell alignment**: Commonmarker's Ruby API does not expose `:left`/`:center`/`:right` alignment. The first pass will skip alignment; if it becomes important later, we would need to parse the raw markdown separator row or switch the table rendering path to use `node.to_html`.
- **Existing documents**: Previously opened files won't have table nodes in `document_nodes` until they are reopened and re-parsed. This is consistent with how versioned parsing already works.
- **Malformed tables**: Rows with fewer or more cells than the header will render whatever cells exist. We won't add complex normalization on the first pass.
- **Per-cell selection**: Because each `table_cell` becomes a block, a user can select text within one cell or across multiple cells. Selecting across rows works the same way as selecting across paragraphs.
