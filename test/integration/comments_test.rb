require "test_helper"

class CommentsTest < ActionDispatch::IntegrationTest
  test "creates a comment with offsets" do
    file = Tempfile.new(["sample", ".md"])
    file.write("# Hello world")
    file.close

    get open_documents_path, params: { file_path: file.path }
    document = Document.find_by(file_path: File.realpath(file.path))

    post document_comments_path(document), params: {
      content: "A comment",
      start_block_id: "block-1",
      end_block_id: "block-1",
      start_offset: 3,
      end_offset: 8,
      selected_text: "Hello",
      prefix_text: "# ",
      postfix_text: " world"
    }

    assert_redirected_to open_documents_path(file_path: document.file_path)
    comment = document.comments.last
    assert_equal "A comment", comment.content
    assert_equal 3, comment.start_offset
    assert_equal 8, comment.end_offset
  ensure
    file.unlink
  end
end
