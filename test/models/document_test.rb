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

  test "save_source_file! updates file on disk, content, bumps version v1 to v2, reparses nodes, and archives comments" do
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
      result = document.save_source_file!(new_content)

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

  test "save_source_file! is a no-op when content has not changed" do
    Dir.mktmpdir do |dir|
      file_path = File.join(dir, "test.md")
      content = "# Unchanged Content\n\nParagraph."
      File.write(file_path, content)

      document = Document.open(file_path)
      initial_version = document.current_version

      result = document.save_source_file!(content)

      assert_equal false, result
      assert_equal initial_version, document.reload.current_version
      assert_equal "v1", document.current_version.version
    end
  end

  test "save_source_file! normalizes CRLF to LF" do
    Dir.mktmpdir do |dir|
      file_path = File.join(dir, "test.md")
      File.write(file_path, "# Initial")

      document = Document.open(file_path)
      document.save_source_file!("Line 1\r\nLine 2\r\n")

      assert_equal "Line 1\nLine 2\n", File.read(file_path)
      assert_equal "Line 1\nLine 2\n", document.reload.content
    end
  end

  test "save_source_file! rejects HTML and text documents and blank content" do
    Dir.mktmpdir do |dir|
      html_path = File.join(dir, "test.html")
      File.write(html_path, "<h1>Hello</h1>")
      html_doc = Document.open(html_path)

      html_error = assert_raises(ArgumentError) do
        html_doc.save_source_file!("<h1>Updated</h1>")
      end
      assert_match(/markdown/i, html_error.message)

      txt_path = File.join(dir, "test.txt")
      File.write(txt_path, "Hello plain text")
      txt_doc = Document.open(txt_path)
      assert txt_doc.text?

      txt_error = assert_raises(ArgumentError) do
        txt_doc.save_source_file!("Updated text")
      end
      assert_match(/markdown/i, txt_error.message)

      md_path = File.join(dir, "test.md")
      File.write(md_path, "# Hello")
      md_doc = Document.open(md_path)

      blank_error = assert_raises(ArgumentError) do
        md_doc.save_source_file!("   \n\t  ")
      end
      assert_match(/blank/i, blank_error.message)
    end
  end

  test "save_source_file! updates org file on disk, content, bumps version v1 to v2, reparses nodes, and rejects blank content" do
    Dir.mktmpdir do |dir|
      file_path = File.join(dir, "notes.org")
      File.write(file_path, "* Initial Heading\n\nInitial paragraph.")

      document = Document.open(file_path)
      assert document.org?
      assert_equal "v1", document.current_version.version
      initial_nodes = document.document_nodes.pluck(:id)

      new_content = "* Updated Heading\n\n- Updated item\n"
      assert document.save_source_file!(new_content)
      assert_equal new_content, File.read(file_path)
      assert_equal new_content, document.reload.content
      assert_equal "v2", document.current_version.version
      assert_not_equal initial_nodes, document.document_nodes.pluck(:id)
      assert_includes document.table_of_contents.map(&:text), "Updated Heading"

      blank_error = assert_raises(ArgumentError) do
        document.save_source_file!("   \n\t  ")
      end
      assert_match(/blank/i, blank_error.message)
    end
  end

  test "destroy! removes versions, nested nodes, html contents, and comments while keeping the file on disk" do
    Dir.mktmpdir do |dir|
      file_path = File.join(dir, "keep-me.html")
      File.write(file_path, "<h1>Title</h1><p>Body</p>")

      document = Document.open(file_path)
      first_version = document.current_version
      first_html_id = first_version.content_id
      first_comment = first_version.comments.create!(content: "First version note")

      File.write(file_path, "<h1>Updated</h1><p>More text</p>")
      document.parse_ast_and_save!(metadata: Documents::AstParseable::ParseMetadata.new(size: 32, last_modified_at: Time.current + 1.second))
      second_version = document.reload.current_version
      second_html_id = second_version.content_id
      second_comment = second_version.comments.create!(content: "Second version note")

      other_document = Document.create!(file_path: File.join(dir, "other.md"), content: "# Other", file_type: "markdown")
      other_document.parse_ast_and_save!(metadata: Documents::AstParseable::ParseMetadata.new(size: 10, last_modified_at: Time.current))

      assert document.destroy!
      assert document.destroyed?
      assert File.exist?(file_path)
      assert_not Document.exists?(document.id)
      assert_not DocumentVersion.where(id: [ first_version.id, second_version.id ]).exists?
      assert_not DocumentNode.where(document_version_id: [ first_version.id, second_version.id ]).exists?
      assert_not HtmlContent.where(id: [ first_html_id, second_html_id ]).exists?
      assert_not Comment.where(id: [ first_comment.id, second_comment.id ]).exists?

      assert Document.exists?(other_document.id)
      assert other_document.current_version.document_nodes.exists?
    end
  end

  test "destroy! deletes large documents with nested nodes in constant SQL queries" do
    document = Document.create!(file_path: "/tmp/large-destroy.org", content: "* Large", file_type: "org")
    version = document.document_versions.create!(version: "v1", size: 1000, last_modified_at: Time.current)
    document.update_column(:current_version_id, version.id)
    version.comments.create!(content: "Large doc comment")

    now = Time.current
    rows = []
    4_000.times do |i|
      root_id = "large-root-#{i}"
      rows << { id: root_id, document_version_id: version.id, parent_id: nil, node_type: "heading", position: i, content: "Section #{i}", created_at: now, updated_at: now }
      2.times do |j|
        child_id = "large-child-#{i}-#{j}"
        rows << { id: child_id, document_version_id: version.id, parent_id: root_id, node_type: "paragraph", position: j, content: "Para #{j}", created_at: now, updated_at: now }
        rows << { id: "large-leaf-#{i}-#{j}", document_version_id: version.id, parent_id: child_id, node_type: "text", position: 0, content: "Text", created_at: now, updated_at: now }
      end
    end
    rows.each_slice(2_000) { |slice| DocumentNode.insert_all!(slice) }
    assert_equal 20_000, version.document_nodes.count

    query_count = 0
    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
      query_count += 1 unless payload[:name] == "SCHEMA"
    end

    begin
      document.destroy!
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber)
    end

    assert_operator query_count, :<=, 12
    assert_not Document.exists?(document.id)
    assert_not DocumentVersion.exists?(version.id)
    assert_not DocumentNode.where(document_version_id: version.id).exists?
    assert_not Comment.where(document_id: document.id).exists?
  end
end
