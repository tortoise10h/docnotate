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

  test "destroys a comment via turbo stream" do
    file = Tempfile.new([ "sample", ".md" ])
    file.write("# Hello world")
    file.close

    get open_documents_path, params: { file_path: file.path }
    document = Document.find_by(file_path: File.realpath(file.path))
    comment = document.comments.create!(
      content: "To be deleted",
      start_block_id: "block-1", end_block_id: "block-1",
      start_offset: 3, end_offset: 8,
      selected_text: "Hello", prefix_text: "# ", postfix_text: " world"
    )

    assert_difference("Comment.count", -1) do
      delete document_comment_path(document, comment), as: :turbo_stream
    end

    assert_response :ok
    assert_match %r{text/vnd.turbo-stream.html}, response.content_type
    refute_match "To be deleted", response.body
  ensure
    file.unlink
  end

  test "updates a comment via turbo stream" do
    file = Tempfile.new([ "sample", ".md" ])
    file.write("# Hello world")
    file.close

    get open_documents_path, params: { file_path: file.path }
    document = Document.find_by(file_path: File.realpath(file.path))
    comment = document.comments.create!(
      content: "Original",
      start_block_id: "block-1", end_block_id: "block-1",
      start_offset: 3, end_offset: 8,
      selected_text: "Hello", prefix_text: "# ", postfix_text: " world"
    )

    patch document_comment_path(document, comment),
          params: { content: "Updated body" }, as: :turbo_stream

    assert_response :ok
    assert_match %r{text/vnd.turbo-stream.html}, response.content_type
    assert_equal "Updated body", comment.reload.content
  ensure
    file.unlink
  end

  test "update with blank content renders 422 turbo stream" do
    file = Tempfile.new([ "sample", ".md" ])
    file.write("# Hello world")
    file.close

    get open_documents_path, params: { file_path: file.path }
    document = Document.find_by(file_path: File.realpath(file.path))
    comment = document.comments.create!(
      content: "Original",
      start_block_id: "block-1", end_block_id: "block-1",
      start_offset: 3, end_offset: 8,
      selected_text: "Hello", prefix_text: "# ", postfix_text: " world"
    )

    patch document_comment_path(document, comment),
          params: { content: "" }, as: :turbo_stream

    assert_response :unprocessable_entity
    assert_match %r{text/vnd.turbo-stream.html}, response.content_type
    assert_equal "Original", comment.reload.content
  ensure
    file.unlink
  end

  test "update with foreign comment id raises not found" do
    file = Tempfile.new([ "sample", ".md" ])
    file.write("# Hello world")
    file.close

    other_file = Tempfile.new([ "other", ".md" ])
    other_file.write("# Other")
    other_file.close

    get open_documents_path, params: { file_path: file.path }
    document = Document.find_by(file_path: File.realpath(file.path))

    get open_documents_path, params: { file_path: other_file.path }
    other_document = Document.find_by(file_path: File.realpath(other_file.path))
    other_comment = other_document.comments.create!(
      content: "Other comment",
      start_block_id: "block-1", end_block_id: "block-1",
      start_offset: 3, end_offset: 8,
      selected_text: "Other", prefix_text: "# ", postfix_text: ""
    )

    patch document_comment_path(document, other_comment),
          params: { content: "x" }, as: :turbo_stream

    assert_response :not_found
  ensure
    file.unlink
    other_file.unlink
  end

  test "toggle_resolved flips the resolved flag for archived comments" do
    file = Tempfile.new([ "sample", ".md" ])
    file.write("# Hello world")
    file.close

    get open_documents_path, params: { file_path: file.path }
    document = Document.find_by(file_path: File.realpath(file.path))
    archived_comment = document.comments.create!(
      content: "Archived comment",
      start_block_id: "block-1", end_block_id: "block-1",
      start_offset: 3, end_offset: 8,
      selected_text: "Hello", prefix_text: "# ", postfix_text: " world"
    )

    document.update!(content: "# Updated world")
    document.parse_ast_and_save!(
      metadata: Documents::AstParseable::ParseMetadata.new(size: 200, last_modified_at: Time.current)
    )

    assert_not archived_comment.reload.is_resolved

    patch document_comment_resolver_path(document, archived_comment), as: :turbo_stream

    assert_response :ok
    assert archived_comment.reload.is_resolved
    assert_match %r{text/vnd.turbo-stream.html}, response.content_type
    assert_match "document__archived-comment--resolved", response.body
    assert_match "Resolved", response.body
  ensure
    file.unlink
  end

  test "toggle_resolved rejects current-version comments" do
    file = Tempfile.new([ "sample", ".md" ])
    file.write("# Hello world")
    file.close

    get open_documents_path, params: { file_path: file.path }
    document = Document.find_by(file_path: File.realpath(file.path))
    current_comment = document.comments.create!(
      content: "Current comment",
      start_block_id: "block-1", end_block_id: "block-1",
      start_offset: 3, end_offset: 8,
      selected_text: "Hello", prefix_text: "# ", postfix_text: " world"
    )

    patch document_comment_resolver_path(document, current_comment), as: :turbo_stream

    assert_response :unprocessable_entity
    assert_not current_comment.reload.is_resolved
  ensure
    file.unlink
  end

  test "version resolver marks all comments of a version resolved when checked" do
    file = Tempfile.new([ "sample", ".md" ])
    file.write("# Hello world")
    file.close

    get open_documents_path, params: { file_path: file.path }
    document = Document.find_by(file_path: File.realpath(file.path))
    document.comments.create!(
      content: "First comment",
      start_block_id: "block-1", end_block_id: "block-1",
      start_offset: 3, end_offset: 8,
      selected_text: "Hello", prefix_text: "# ", postfix_text: " world"
    )
    document.comments.create!(
      content: "Second comment",
      start_block_id: "block-1", end_block_id: "block-1",
      start_offset: 3, end_offset: 8,
      selected_text: "Hello", prefix_text: "# ", postfix_text: " world"
    )

    document.update!(content: "# Updated world")
    document.parse_ast_and_save!(
      metadata: Documents::AstParseable::ParseMetadata.new(size: 200, last_modified_at: Time.current)
    )

    archived_version = document.document_versions.order(:created_at).first
    archived_comments = -> { document.archived_comments.where(document_version: archived_version) }
    assert_equal 2, archived_comments.call.count
    assert archived_comments.call.none?(&:is_resolved)

    patch document_version_resolver_path(document),
          params: { document_version_id: archived_version.id, resolved: "1" }, as: :turbo_stream

    assert_response :ok
    assert_match %r{text/vnd.turbo-stream.html}, response.content_type
    assert archived_comments.call.all?(&:is_resolved)
    assert_match "document__archived-comment--resolved", response.body
  ensure
    file.unlink
  end

  test "version resolver unresolves all comments of a version when unchecked" do
    file = Tempfile.new([ "sample", ".md" ])
    file.write("# Hello world")
    file.close

    get open_documents_path, params: { file_path: file.path }
    document = Document.find_by(file_path: File.realpath(file.path))
    document.comments.create!(
      content: "First comment",
      start_block_id: "block-1", end_block_id: "block-1",
      start_offset: 3, end_offset: 8,
      selected_text: "Hello", prefix_text: "# ", postfix_text: " world"
    )

    document.update!(content: "# Updated world")
    document.parse_ast_and_save!(
      metadata: Documents::AstParseable::ParseMetadata.new(size: 200, last_modified_at: Time.current)
    )

    archived_version = document.document_versions.order(:created_at).first
    archived_version.resolve_all_comments!(true)
    assert document.archived_comments.where(document_version: archived_version).all?(&:is_resolved)

    patch document_version_resolver_path(document),
          params: { document_version_id: archived_version.id, resolved: "0" }, as: :turbo_stream

    assert_response :ok
    assert document.archived_comments.where(document_version: archived_version).all? { |comment| !comment.is_resolved }
  ensure
    file.unlink
  end

  test "version resolver rejects the current version" do
    file = Tempfile.new([ "sample", ".md" ])
    file.write("# Hello world")
    file.close

    get open_documents_path, params: { file_path: file.path }
    document = Document.find_by(file_path: File.realpath(file.path))
    current_comment = document.comments.create!(
      content: "Current comment",
      start_block_id: "block-1", end_block_id: "block-1",
      start_offset: 3, end_offset: 8,
      selected_text: "Hello", prefix_text: "# ", postfix_text: " world"
    )

    patch document_version_resolver_path(document),
          params: { document_version_id: document.current_version_id, resolved: "1" }, as: :turbo_stream

    assert_response :unprocessable_entity
    assert_not current_comment.reload.is_resolved
  ensure
    file.unlink
  end

  test "comment payload includes current and archived keys" do
    file = Tempfile.new([ "sample", ".md" ])
    file.write("# Hello world")
    file.close

    get open_documents_path, params: { file_path: file.path }
    document = Document.find_by(file_path: File.realpath(file.path))
    document.comments.create!(
      content: "Archived comment",
      start_block_id: "block-1", end_block_id: "block-1",
      start_offset: 3, end_offset: 8,
      selected_text: "Hello", prefix_text: "# ", postfix_text: " world"
    )
    document.update!(content: "# Updated world")
    document.parse_ast_and_save!(
      metadata: Documents::AstParseable::ParseMetadata.new(size: 200, last_modified_at: Time.current)
    )

    get open_documents_path, params: { file_path: file.path }

    assert_response :ok
    payload = Nokogiri::HTML4(response.body).at("#comment_payload_source")&.text
    assert payload.present?
    parsed = JSON.parse(payload)
    assert parsed.key?("current")
    assert parsed.key?("archived")
    assert_equal 1, parsed["archived"].length
    assert_equal "Archived comment", parsed["archived"].first["content"]
  ensure
    file.unlink
  end
end
