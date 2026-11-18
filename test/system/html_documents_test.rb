require "application_system_test_case"

class HtmlDocumentsSystemTest < ApplicationSystemTestCase
  test "renders the html file in the frame and lists its headings in the table of contents" do
    file = Tempfile.new([ "system", ".html" ])
    file.write(%(<html><body><h2>Intro</h2><p>Frame text</p></body></html>))
    file.close

    visit open_documents_path(file_path: file.path)

    within_frame find("iframe.html-viewer__frame") do
      assert_text "Frame text"
    end
    assert_selector ".document__toc-item", text: "Intro", visible: :all
    assert_no_selector "button[aria-label='Wide view']"

    toggle_left = find(".document__toc-toggle").rect.x
    find(".document__toc-toggle").click
    assert_selector ".document__toc-panel"
    assert_equal toggle_left, find(".document__toc-panel").rect.x
  ensure
    file.unlink
  end
end
