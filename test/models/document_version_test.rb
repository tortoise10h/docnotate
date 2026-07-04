require "test_helper"

class DocumentVersionTest < ActiveSupport::TestCase
  test "current_version returns the explicitly assigned version" do
    document = Document.create!(
      file_path: "/tmp/doc.md",
      content: "# Hello",
      file_type: "markdown"
    )
    document.parse_ast_and_save!(metadata: Documents::AstParseable::ParseMetadata.new(size: 100, last_modified_at: 1.day.ago))
    first_version = document.current_version
    document.document_versions.create!(version: "v2", size: 100, last_modified_at: Time.current)
    second_version = document.document_versions.order(:created_at).last
    document.update_column(:current_version_id, second_version.id)
    document.association(:current_version).reset

    assert_equal second_version, document.current_version
    assert_equal first_version, document.document_versions.order(:created_at).first
  end
end
