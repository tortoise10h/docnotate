require "test_helper"

class CommentTest < ActiveSupport::TestCase
  test "document_version_id must belong to the same document" do
    document = Document.create!(
      file_path: "/tmp/doc.md",
      content: "# Hello",
      file_type: "markdown",
      version: "v1",
      size: 100,
      last_modified_at: Time.current
    )
    document.parse_ast_and_save!

    other_document = Document.create!(
      file_path: "/tmp/other.md",
      content: "# Other",
      file_type: "markdown",
      version: "v1",
      size: 100,
      last_modified_at: Time.current
    )
    other_document.parse_ast_and_save!

    comment = document.comments.new(content: "Comment")
    comment.document_version = other_document.current_version

    assert_not comment.valid?
    assert_includes comment.errors[:document_version_id], "must belong to the same document"
  end

  test "auto-assigns current document version on create" do
    document = Document.create!(
      file_path: "/tmp/doc.md",
      content: "# Hello",
      file_type: "markdown",
      version: "v1",
      size: 100,
      last_modified_at: Time.current
    )
    document.parse_ast_and_save!

    comment = document.comments.create!(content: "Comment")

    assert_equal document.current_version, comment.document_version
  end
end
