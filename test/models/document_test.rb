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

  test "normalize_file_path strips file:// prefix, localhost authority, fragments, queries, and decodes percent encoding" do
    assert_equal "/Users/test/doc.html", Document.normalize_file_path("file:///Users/test/doc.html")
    assert_equal "/Users/test/doc.html", Document.normalize_file_path("file://localhost/Users/test/doc.html")
    assert_equal "/Users/test/my notes.html", Document.normalize_file_path("file:///Users/test/my%20notes.html#heading")
    assert_equal "/Users/test/doc.html", Document.normalize_file_path("file:///Users/test/doc.html?v=1")
    assert_equal "C:/Users/test/doc.html", Document.normalize_file_path("file:///C:/Users/test/doc.html")
    assert_equal "/Users/test/doc.html", Document.normalize_file_path("/Users/test/doc.html")
    assert_nil Document.normalize_file_path(nil)
  end

  test "save_markdown_file! updates file on disk, content, bumps version v1 to v2, reparses nodes, and archives comments" do
    Dir.mktmpdir do |dir|
      file_path = File.join(dir, "test.md")
      File.write(file_path, "# Initial Title\n\nInitial paragraph text.")

      document = Document.open(file_path)
      assert_equal "v1", document.current_version.version
      initial_version = document.current_version
      initial_nodes = document.document_nodes.to_a

      comment = document.create_comment!(content: "Note on heading", selected_text: "Initial Title")
      assert_includes document.highlight_comments.map { |c| c[:id] }, comment.id
      assert_empty document.archived_comments

      new_content = "# Updated Heading\n\n- Point one\n- Point two"
      result = document.save_markdown_file!(new_content)

      assert result
      assert_equal new_content, File.read(file_path)
      assert_equal new_content, document.reload.content
      assert_equal "v2", document.current_version.version
      assert_not_equal initial_version, document.current_version
      assert_not_equal initial_nodes.map(&:id), document.document_nodes.pluck(:id)

      assert_empty document.highlight_comments
      assert_includes document.archived_comments, comment
    end
  end

  test "save_markdown_file! is a no-op when content has not changed" do
    Dir.mktmpdir do |dir|
      file_path = File.join(dir, "test.md")
      content = "# Unchanged Content\n\nParagraph."
      File.write(file_path, content)

      document = Document.open(file_path)
      initial_version = document.current_version

      result = document.save_markdown_file!(content)

      assert_equal false, result
      assert_equal initial_version, document.reload.current_version
      assert_equal "v1", document.current_version.version
    end
  end

  test "save_markdown_file! normalizes CRLF to LF" do
    Dir.mktmpdir do |dir|
      file_path = File.join(dir, "test.md")
      File.write(file_path, "# Initial")

      document = Document.open(file_path)
      document.save_markdown_file!("Line 1\r\nLine 2\r\n")

      assert_equal "Line 1\nLine 2\n", File.read(file_path)
      assert_equal "Line 1\nLine 2\n", document.reload.content
    end
  end

  test "save_markdown_file! rejects HTML documents and blank content" do
    Dir.mktmpdir do |dir|
      html_path = File.join(dir, "test.html")
      File.write(html_path, "<h1>Hello</h1>")
      html_doc = Document.open(html_path)

      html_error = assert_raises(ArgumentError) do
        html_doc.save_markdown_file!("<h1>Updated</h1>")
      end
      assert_match(/markdown/i, html_error.message)

      md_path = File.join(dir, "test.md")
      File.write(md_path, "# Hello")
      md_doc = Document.open(md_path)

      blank_error = assert_raises(ArgumentError) do
        md_doc.save_markdown_file!("   \n\t  ")
      end
      assert_match(/blank/i, blank_error.message)
    end
  end
end
