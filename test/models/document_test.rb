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
end
