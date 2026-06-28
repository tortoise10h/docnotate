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
    first_version = document.version

    get open_documents_path, params: { file_path: file.path }
    document.reload

    assert_equal first_version, document.version
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
end
