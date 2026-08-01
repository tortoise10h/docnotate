require "test_helper"

class DocumentsTest < ActionDispatch::IntegrationTest
  test "opens a document from a local file path" do
    file = Tempfile.new(["sample", ".md"])
    file.write("# Hello")
    file.close

    get open_documents_path, params: { file_path: file.path }

    document = Document.find_by(file_path: File.realpath(file.path))
    assert document.present?
    assert_response :success
    assert_select ".document__title", File.basename(file.path)
  ensure
    file.unlink
  end

  test "renders markdown tables" do
    file = Tempfile.new(["table", ".md"])
    file.write("| Name | Status |\n| --- | --- |\n| Alice | Active |")
    file.close

    get open_documents_path, params: { file_path: file.path }

    assert_response :success
    assert_select "table.document-node--table"
    assert_select "table > thead > tr.document-node--table-row"
    assert_select "table > tbody > tr.document-node--table-row"
    assert_select "thead th.document-node--table-cell-th", text: "Name"
    assert_select "tbody td.document-node--table-cell", text: "Active"
  ensure
    file.unlink
  end

  test "resolves a relative file path to an absolute path" do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        File.write("relative.md", "# Hello")

        get open_documents_path, params: { file_path: "relative.md" }

        assert_response :success
        document = Document.find_by(file_path: File.realpath("relative.md", dir))
        assert document.present?
      end
    end
  end

  test "does not bump version when file has not changed" do
    file = Tempfile.new(["sample", ".md"])
    file.write("# Hello")
    file.close

    get open_documents_path, params: { file_path: file.path }
    document = Document.find_by(file_path: File.realpath(file.path))
    first_version = document.current_version.version

    get open_documents_path, params: { file_path: file.path }
    document.reload

    assert_equal first_version, document.current_version.version
  ensure
    file.unlink
  end

  test "replaces stale document nodes when the file is updated" do
    file = Tempfile.new(["sample", ".md"])
    file.write("# Hello")
    file.close

    get open_documents_path, params: { file_path: file.path }
    document = Document.find_by(file_path: File.realpath(file.path))
    first_version = document.current_version.version
    first_node_count = document.document_nodes.count

    sleep 1
    File.write(file.path, "# World")
    get open_documents_path, params: { file_path: file.path }
    document.reload

    assert_not_equal first_version, document.current_version.version
    assert_equal first_node_count, document.document_nodes.count,
                 "re-parsing should replace stale nodes, not stack new ones on top"
    assert_equal "# World", document.content
    text_nodes = document.document_nodes.where(node_type: "text").pluck(:content)
    assert_includes text_nodes, "World"
    assert_not_includes text_nodes, "Hello", "stale node from previous version should be removed"
  ensure
    file.unlink
  end

  test "redirects home when file path is blank" do
    get open_documents_path

    assert_redirected_to root_path
    assert_equal "No file provided", flash[:alert]
  end

  test "redirects home when file does not exist" do
    get open_documents_path, params: { file_path: "/non/existent/file.md" }

    assert_redirected_to root_path
    assert_equal "File not found", flash[:alert]
  end

  test "renders unsupported file error for non-markdown files" do
    file = Tempfile.new(["sample", ".txt"])
    file.write("Hello")
    file.close

    get open_documents_path, params: { file_path: file.path }

    assert_response :unsupported_media_type
    assert_select ".error__title", "Unsupported file type"
    assert_select ".error__message", /#{File.basename(file.path)}/
    assert_select "a[href=?]", root_path, text: /Return to Home/
  ensure
    file.unlink
  end
end
