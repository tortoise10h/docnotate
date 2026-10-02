require "test_helper"

class DocumentTest < ActiveSupport::TestCase
  test "parse_ast_and_save! creates a new version, updates current_version, and drops previous version nodes" do
    document = Document.create!(
      file_path: "/tmp/doc.md",
      content: "# Hello",
      file_type: "markdown"
    )
    document.parse_ast_and_save!(metadata: Documents::AstParseable::ParseMetadata.new(size: 100, last_modified_at: Time.current))

    first_version = document.current_version
    first_version.comments.create!(content: "A comment")

    document.update!(content: "# World")
    document.parse_ast_and_save!(metadata: Documents::AstParseable::ParseMetadata.new(size: 200, last_modified_at: Time.current + 1.second))

    assert_equal 2, document.document_versions.count
    assert_not_equal first_version, document.current_version
    assert_equal document.current_version, document.reload.current_version
    assert_empty first_version.reload.document_nodes
    assert_equal 1, first_version.comments.count
    assert_not_empty document.current_version.document_nodes
  end

  test "archived_comments excludes comments on the current version" do
    document = Document.create!(
      file_path: "/tmp/doc.md",
      content: "# Hello",
      file_type: "markdown"
    )
    document.parse_ast_and_save!(metadata: Documents::AstParseable::ParseMetadata.new(size: 100, last_modified_at: Time.current))
    first_version = document.current_version
    archived_comment = first_version.comments.create!(content: "Old comment")

    document.update!(content: "# World")
    document.parse_ast_and_save!(metadata: Documents::AstParseable::ParseMetadata.new(size: 200, last_modified_at: Time.current + 1.second))
    current_comment = document.current_version.comments.create!(content: "New comment")

    assert_includes document.archived_comments, archived_comment
    assert_not_includes document.archived_comments, current_comment
  end

  test "archived_comments_by_version groups archived comments by version in descending version order" do
    document = Document.create!(
      file_path: "/tmp/doc.md",
      content: "# Hello",
      file_type: "markdown"
    )

    document.parse_ast_and_save!(metadata: Documents::AstParseable::ParseMetadata.new(size: 100, last_modified_at: Time.current))
    first_version = document.current_version
    first_version.comments.create!(content: "First version comment A")
    first_version.comments.create!(content: "First version comment B")

    document.update!(content: "# World")
    document.parse_ast_and_save!(metadata: Documents::AstParseable::ParseMetadata.new(size: 200, last_modified_at: Time.current + 1.second))
    second_version = document.reload.current_version
    second_version.comments.create!(content: "Second version comment")

    document.update!(content: "# Updated")
    document.parse_ast_and_save!(metadata: Documents::AstParseable::ParseMetadata.new(size: 300, last_modified_at: Time.current + 2.seconds))

    grouped = document.archived_comments_by_version
    versions = grouped.keys

    assert_equal 2, versions.size
    assert_equal second_version, versions.first
    assert_equal first_version, versions.last
    assert_equal [ "Second version comment" ], grouped[second_version].map(&:content)
    assert_equal [ "First version comment A", "First version comment B" ], grouped[first_version].map(&:content)
  end

  test "parses markdown tables into selectable document nodes" do
    document = Document.create!(
      file_path: "/tmp/table.md",
      content: "| Name | Status |\n| --- | --- |\n| Alice | Active |",
      file_type: "markdown"
    )

    document.parse_ast_and_save!(metadata: Documents::AstParseable::ParseMetadata.new(size: 100, last_modified_at: Time.current))

    table = document.document_nodes.find_by(node_type: "table")
    header_row = table.children.ordered.first
    header_cells = header_row.children.ordered

    assert table
    assert_equal 1, document.document_nodes.where(node_type: "table").count
    assert_equal 2, document.document_nodes.where(node_type: "table_row").count
    assert_equal 4, document.document_nodes.where(node_type: "table_cell").count
    assert_equal [ true, true ], header_cells.map { |cell| cell.meta["is_header"] }
    assert header_cells.all? { |cell| cell.node_id.start_with?("block-") }
  end

  test "table_of_contents extracts h1 through h3 headings in document order" do
    document = Document.create!(
      file_path: "/tmp/headings.md",
      content: "# Heading **with** `code`\n\n## Nested [link](https://example.com)\n\n### Third level\n\n#### Too deep\n\n# Last heading",
      file_type: "markdown"
    )
    document.parse_ast_and_save!(metadata: Documents::AstParseable::ParseMetadata.new(size: 100, last_modified_at: Time.current))

    entries = document.table_of_contents
    expected_headings = document.document_nodes.where(node_type: "heading").where("heading_level <= 3").ordered

    assert_equal expected_headings.map(&:node_id), entries.map(&:id)
    assert_equal [ 1, 2, 3, 1 ], entries.map(&:level)
    assert_equal [ "Heading with code", "Nested link", "Third level", "Last heading" ], entries.map(&:text)
  end

  test "table_of_contents returns an empty array when there are no h1 through h3 headings" do
    document = Document.create!(
      file_path: "/tmp/no-headings.md",
      content: "A paragraph without headings.\n\n#### Only a deeper heading",
      file_type: "markdown"
    )
    document.parse_ast_and_save!(metadata: Documents::AstParseable::ParseMetadata.new(size: 100, last_modified_at: Time.current))

    assert_empty document.table_of_contents
  end

  test "recently_opened orders opened documents by last_opened_at and excludes never-opened documents" do
    oldest = Document.create!(file_path: "/tmp/old.md", content: "old", file_type: "markdown", last_opened_at: 1.hour.ago)
    newest = Document.create!(file_path: "/tmp/new.md", content: "new", file_type: "markdown", last_opened_at: Time.current)
    never_opened = Document.create!(file_path: "/tmp/never.md", content: "never", file_type: "markdown")

    assert_equal [ newest, oldest ], Document.recently_opened.to_a
    assert_not_includes Document.recently_opened, never_opened
  end
end
