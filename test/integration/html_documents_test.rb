require "test_helper"

class HtmlDocumentsTest < ActionDispatch::IntegrationTest
  test "opens an html file and renders it in a sandboxed iframe" do
    file = Tempfile.new([ "report", ".html" ])
    file.write(%(<html><body><h1>Report</h1><p>Body text</p></body></html>))
    file.close

    get open_documents_path, params: { file_path: file.path }

    document = Document.find_by!(file_path: File.realpath(file.path))
    assert document.html?
    assert_response :success
    assert_select ".document--wide"
    assert_select "iframe.html-viewer__frame[sandbox='allow-scripts'][src=?]", "#{document_content_path(document)}/"
    assert_select ".document__toc-item", text: "Report"
  ensure
    file.unlink
  end

  test "wires the comment panel and table of contents to the frame" do
    file = Tempfile.new([ "wired", ".html" ])
    file.write(%(<html><body><h2>Wired</h2><p>Body</p></body></html>))
    file.close

    get open_documents_path, params: { file_path: file.path }

    assert_select "#document_paper[data-comment-highlight-remote-value='true'][data-comment-popover-remote-value='true']"
    assert_select "#document_paper .document__comment-nav [data-comment-highlight-target='navTotal']"
    assert_select "#document_paper .html-viewer[data-comment-popover-target='content']"
    assert_select ".document__toc[data-table-of-contents-html-value='true']"
    assert_select "#previous-comments"
  ensure
    file.unlink
  end

  test "serves the annotated html of the current version" do
    file = Tempfile.new([ "served", ".htm" ])
    file.write(%(<html><body><p>Served text</p></body></html>))
    file.close

    get open_documents_path, params: { file_path: file.path }
    document = Document.find_by!(file_path: File.realpath(file.path))
    get "#{document_content_path(document)}/"

    assert_response :success
    assert_match %r{text/html}, response.content_type
    assert_select "p[data-docnotate-block]", text: "Served text"
  ensure
    file.unlink
  end

  test "stores annotated html whose block ids match the version's nodes" do
    file = Tempfile.new([ "stored", ".html" ])
    file.write(%(<html><body><h1>Stored</h1><p>Body</p></body></html>))
    file.close

    get open_documents_path, params: { file_path: file.path }
    document = Document.find_by!(file_path: File.realpath(file.path))
    version = document.current_version

    annotated_ids = Nokogiri::HTML5(version.content.annotated_html).css("[data-docnotate-block]").map { |el| el["data-docnotate-block"] }
    assert_equal version.document_nodes.pluck(:node_id).sort, annotated_ids.sort
  ensure
    file.unlink
  end

  test "does not bump the version when an html file is reopened unchanged" do
    file = Tempfile.new([ "steady", ".html" ])
    file.write(%(<html><body><p>Steady</p></body></html>))
    file.close

    get open_documents_path, params: { file_path: file.path }
    document = Document.find_by!(file_path: File.realpath(file.path))
    first_version = document.current_version

    get open_documents_path, params: { file_path: file.path }

    assert_equal first_version, document.reload.current_version
  ensure
    file.unlink
  end

  test "creates a new version with replaced nodes when the html file changes" do
    file = Tempfile.new([ "changing", ".html" ])
    file.write(%(<html><body><h2>Before</h2><p>Old body</p></body></html>))
    file.close

    get open_documents_path, params: { file_path: file.path }
    document = Document.find_by!(file_path: File.realpath(file.path))
    first_version = document.current_version

    File.write(file.path, %(<html><body><h2>After</h2><p>New body text</p></body></html>))
    get open_documents_path, params: { file_path: file.path }
    document.reload

    assert_not_equal first_version, document.current_version
    assert_match(/After/, document.current_version.content.annotated_html)
    assert_no_match(/Before/, document.current_version.content.annotated_html)
    assert_equal %w[heading p], document.current_version.document_nodes.order(:position).pluck(:node_type)
    assert_empty first_version.reload.document_nodes
  ensure
    file.unlink
  end

  test "rejects unsupported file types" do
    file = Tempfile.new([ "doc", ".pdf" ])
    file.write("%PDF")
    file.close

    get open_documents_path, params: { file_path: file.path }

    assert_response :unsupported_media_type
    assert_select ".error__title", "Unsupported file type"
  ensure
    file.unlink
  end

  test "serves sibling assets and refuses files outside the document's directory" do
    root = Dir.mktmpdir
    dir = File.join(root, "doc")
    Dir.mkdir(dir)
    File.write(File.join(dir, "report.html"), %(<html><body><img src="diagram.png"><p>Assets</p></body></html>))
    File.binwrite(File.join(dir, "diagram.png"), "PNG")
    File.write(File.join(dir, "secret.html"), "<p>secret</p>")
    File.write(File.join(root, "outside.css"), "body {}")

    get open_documents_path, params: { file_path: File.join(dir, "report.html") }
    document = Document.find_by!(file_path: File.realpath(File.join(dir, "report.html")))

    get document_content_asset_path(document, "diagram.png")
    assert_response :success
    assert_equal "PNG", response.body
    assert_equal "sandbox allow-scripts", response.headers["Content-Security-Policy"]

    get document_content_asset_path(document, "../outside.css")
    assert_response :not_found

    get document_content_asset_path(document, "secret.html")
    assert_response :not_found
  ensure
    FileUtils.remove_entry(root) if root
  end

  test "opens an html file from a browser file url with file:// prefix" do
    file = Tempfile.new([ "browser-url", ".html" ])
    file.write(%(<html><body><h1>From Browser</h1><p>Body</p></body></html>))
    file.close

    get open_documents_path, params: { file_path: "file://#{file.path}#heading-1" }

    document = Document.find_by!(file_path: File.realpath(file.path))
    assert document.html?
    assert_response :success
    assert_select ".document__title", File.basename(file.path)
  ensure
    file.unlink
  end
end
