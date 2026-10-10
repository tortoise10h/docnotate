require "test_helper"

class HtmlFrameDocumentTest < ActiveSupport::TestCase
  test "inlines the anchor helpers and frame client before the closing body tag" do
    html = HtmlFrameDocument.new("<html><body><p data-docnotate-block=\"block-0a1b2c3d\">Hi</p></body></html>").to_html

    assert_match %r{<script type="module">.*export function blockIdOf.*docnotate:selection.*</script></body>}m, html
  end

  test "appends the script when the document has no body tag" do
    html = HtmlFrameDocument.new("<p>Fragment</p>").to_html

    assert html.start_with?("<p>Fragment</p><script type=\"module\">")
  end
end
