require "test_helper"

class Documents::MarkdownFilesControllerTest < ActionDispatch::IntegrationTest
  test "updates markdown file on disk and redirects with see_other to open_documents_path" do
    Dir.mktmpdir do |dir|
      file_path = File.join(dir, "editable.md")
      File.write(file_path, "# Initial text")
      document = Document.open(file_path)

      patch document_markdown_files_url(document), params: {
        document: { content: "# Updated text\n\nNew paragraph." }
      }

      assert_response :see_other
      assert_redirected_to open_documents_path(file_path: document.file_path)
      assert_equal "# Updated text\n\nNew paragraph.", File.read(file_path)
      assert_equal "# Updated text\n\nNew paragraph.", document.reload.content
      assert_equal "v2", document.current_version.version
    end
  end

  test "returns unprocessable_entity when content is blank" do
    Dir.mktmpdir do |dir|
      file_path = File.join(dir, "editable.md")
      File.write(file_path, "# Initial text")
      document = Document.open(file_path)

      patch document_markdown_files_url(document), params: {
        document: { content: "   " }
      }

      assert_response :unprocessable_entity
      assert_match(/blank/i, response.body)
    end
  end

  test "returns unprocessable_entity when document is not markdown" do
    Dir.mktmpdir do |dir|
      file_path = File.join(dir, "editable.html")
      File.write(file_path, "<h1>Initial text</h1>")
      document = Document.open(file_path)

      patch document_markdown_files_url(document), params: {
        document: { content: "<h1>New text</h1>" }
      }

      assert_response :unprocessable_entity
      assert_match(/markdown/i, response.body)
    end
  end

  test "returns unprocessable_entity on permission error" do
    Dir.mktmpdir do |dir|
      file_path = File.join(dir, "editable.md")
      File.write(file_path, "# Initial text")
      document = Document.open(file_path)

      File.chmod(0o444, dir)

      patch document_markdown_files_url(document), params: {
        document: { content: "# Updated text" }
      }

      assert_response :unprocessable_entity
    ensure
      File.chmod(0o755, dir)
    end
  end

  test "returns turbo stream error when requested as turbo stream" do
    Dir.mktmpdir do |dir|
      file_path = File.join(dir, "editable.md")
      File.write(file_path, "# Initial text")
      document = Document.open(file_path)

      patch document_markdown_files_url(document),
            params: { document: { content: "" } },
            as: :turbo_stream

      assert_response :unprocessable_entity
      assert_match %r{text/vnd.turbo-stream.html}, response.content_type
      assert_match %r{markdown_editor_error}, response.body
    end
  end
end
