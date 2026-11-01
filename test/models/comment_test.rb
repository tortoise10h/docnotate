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

  test "rendered_content renders callouts with shared markup and icons" do
    document = Document.create!(
      file_path: "/tmp/doc.md",
      content: "# Hello",
      file_type: "markdown"
    )
    document.parse_ast_and_save!(metadata: Documents::AstParseable::ParseMetadata.new(size: 100, last_modified_at: Time.current))

    comment = document.comments.build(content: "> [!NOTE] Review Notice\n> Please check this section.")
    html = comment.rendered_content

    assert_includes html, '<div class="callout callout--note">'
    assert_includes html, '<div class="callout__header">'
    assert_includes html, '<span class="callout__icon" aria-hidden="true">'
    assert_includes html, '<span class="callout__title">Review Notice</span>'
    assert_includes html, '<div class="callout__content">'
    assert_includes html, "Please check this section."
  end

  test "rendered_content renders collapsible callouts in comments" do
    document = Document.create!(
      file_path: "/tmp/doc.md",
      content: "# Hello",
      file_type: "markdown"
    )
    document.parse_ast_and_save!(metadata: Documents::AstParseable::ParseMetadata.new(size: 100, last_modified_at: Time.current))

    collapsed_comment = document.comments.build(content: "> [!TIP]- Hidden Suggestion\n> Secret pro-tip.")
    collapsed_html = collapsed_comment.rendered_content
    assert_includes collapsed_html, '<details class="callout callout--tip callout--collapsible">'
    assert_includes collapsed_html, '<summary class="callout__header">'
    assert_includes collapsed_html, '<span class="callout__fold-icon" aria-hidden="true">'
    refute_match %r{<details[^>]*\bopen\b}, collapsed_html

    expanded_comment = document.comments.build(content: "> [!WARNING]+ Immediate Attention\n> Visible warning.")
    expanded_html = expanded_comment.rendered_content
    assert_includes expanded_html, '<details class="callout callout--warning callout--collapsible" open>'
  end

  test "rendered_content neutralizes raw html in callout title and body" do
    document = Document.create!(
      file_path: "/tmp/doc.md",
      content: "# Hello",
      file_type: "markdown"
    )
    document.parse_ast_and_save!(metadata: Documents::AstParseable::ParseMetadata.new(size: 100, last_modified_at: Time.current))

    comment = document.comments.build(content: "> [!NOTE] <script>alert('title')</script>\n> <script>alert('body')</script><img src=x onerror=alert(1)>")
    html = comment.rendered_content

    refute_includes html, "<script>"
    refute_includes html, "<img"
  end
end
