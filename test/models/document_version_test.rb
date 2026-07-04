require "test_helper"

class DocumentVersionTest < ActiveSupport::TestCase
  test "current_version returns the latest by created_at" do
    document = Document.create!(
      file_path: "/tmp/doc.md",
      content: "# Hello",
      file_type: "markdown",
      version: "v1",
      size: 100,
      last_modified_at: Time.current
    )
    first_version = document.document_versions.create!(version: "v1", size: 100, last_modified_at: 1.day.ago)
    second_version = document.document_versions.create!(version: "v2", size: 100, last_modified_at: Time.current)

    assert_equal second_version, document.current_version
    assert_equal first_version, document.document_versions.order(:created_at).first
  end
end
