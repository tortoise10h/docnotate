require "test_helper"

class CommentTest < ActiveSupport::TestCase
  test "document_version_id must belong to the same document" do
    document = Document.create!(
      file_path: "/tmp/doc.md",
      content: "# Hello",
      file_type: "markdown"
    )
    document.parse_ast_and_save!(metadata: Documents::AstParseable::ParseMetadata.new(size: 100, last_modified_at: Time.current))

    other_document = Document.create!(
      file_path: "/tmp/other.md",
      content: "# Other",
      file_type: "markdown"
    )
    other_document.parse_ast_and_save!(metadata: Documents::AstParseable::ParseMetadata.new(size: 100, last_modified_at: Time.current))

    comment = document.comments.new(content: "Comment")
    comment.document_version = other_document.current_version

    assert_not comment.valid?
    assert_includes comment.errors[:document_version_id], "must belong to the same document"
  end

  test "auto-assigns current document version on create" do
    document = Document.create!(
      file_path: "/tmp/doc.md",
      content: "# Hello",
      file_type: "markdown"
    )
    document.parse_ast_and_save!(metadata: Documents::AstParseable::ParseMetadata.new(size: 100, last_modified_at: Time.current))

    comment = document.comments.create!(content: "Comment")

    assert_equal document.current_version, comment.document_version
  end

  test "rendered_content renders markdown" do
    document = Document.create!(
      file_path: "/tmp/doc.md",
      content: "# Hello",
      file_type: "markdown"
    )
    document.parse_ast_and_save!(metadata: Documents::AstParseable::ParseMetadata.new(size: 100, last_modified_at: Time.current))

    comment = document.comments.build(content: "Fix `-v` flag first:\n\n- one\n- two")

    html = comment.rendered_content

    assert_match %r{<p>Fix <code>-v</code> flag first:</p>}, html
    assert_match %r{<li>one</li>}, html
  end

  test "rendered_content neutralizes raw html from agent content" do
    document = Document.create!(
      file_path: "/tmp/doc.md",
      content: "# Hello",
      file_type: "markdown"
    )
    document.parse_ast_and_save!(metadata: Documents::AstParseable::ParseMetadata.new(size: 100, last_modified_at: Time.current))

    comment = document.comments.build(content: "<script>alert(1)</script><img src=x onerror=alert(1)>")

    html = comment.rendered_content
    assert_not_includes html, "<script>"
    assert_not_includes html, "<img"
  end
end
