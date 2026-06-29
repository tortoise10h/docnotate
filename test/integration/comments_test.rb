require "test_helper"

class CommentsTest < ActionDispatch::IntegrationTest
  test "creates a comment via turbo stream" do
    file = Tempfile.new([ "sample", ".md" ])
    file.write("# Hello world")
    file.close

    get open_documents_path, params: { file_path: file.path }
    document = Document.find_by(file_path: File.realpath(file.path))

    assert_difference("Comment.count", +1) do
      post document_comments_path(document),
           params: { content: "A comment", start_block_id: "block-1",
                     end_block_id: "block-1", start_offset: 3, end_offset: 8,
                     selected_text: "Hello", prefix_text: "# ", postfix_text: " world" },
           as: :turbo_stream
    end

    assert_response :ok
    assert_match %r{text/vnd.turbo-stream.html}, response.content_type
    assert_match "A comment", response.body
    comment = document.comments.last
    assert_equal "A comment", comment.content
    assert_equal 3, comment.start_offset
    assert_equal 8, comment.end_offset
  ensure
    file.unlink
  end

  test "create with blank content renders 422 turbo stream" do
    file = Tempfile.new([ "sample", ".md" ])
    file.write("# Hello world")
    file.close

    get open_documents_path, params: { file_path: file.path }
    document = Document.find_by(file_path: File.realpath(file.path))

    assert_no_difference("Comment.count") do
      post document_comments_path(document), params: { content: "" }, as: :turbo_stream
    end

    assert_response :unprocessable_entity
    assert_match %r{text/vnd.turbo-stream.html}, response.content_type
    assert_match "Content", response.body
  ensure
    file.unlink
  end
end
