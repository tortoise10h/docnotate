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
end
