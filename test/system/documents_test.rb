require "application_system_test_case"

class DocumentsSystemTest < ApplicationSystemTestCase
  test "copies file path and swaps icon state from all files row hover actions" do
    file = Tempfile.new([ "copy-row", ".md" ])
    file.write("# Copy Row")
    file.close
    document = Document.open(file.path)

    visit documents_path

    page.execute_script(<<~JS)
      window.__copiedText = null
      Object.defineProperty(navigator, "clipboard", {
        configurable: true,
        value: {
          writeText: async (text) => { window.__copiedText = text }
        }
      })
    JS

    row = find("#document_#{document.id} .documents__row-display")
    row.hover

    copy_button = row.find(".documents__actions button[title='Copy file path']")
    copy_button.click

    assert_selector "#document_#{document.id} .documents__actions button[aria-label='Copied!']"
    assert_equal document.file_path, page.evaluate_script("window.__copiedText")
    assert_selector "#document_#{document.id} svg[data-clipboard-target='defaultIcon'].document__copy-icon--hidden", visible: :all
    assert_selector "#document_#{document.id} svg[data-clipboard-target='successIcon']:not(.document__copy-icon--hidden)", visible: true
  ensure
    file&.unlink
  end

  test "switcher panel extends left of hub toggle and stays within viewport for short, long, and narrow layouts" do
    short_file = Tempfile.new([ "short", ".md" ])
    short_file.write("# Short")
    short_file.close

    long_file = Tempfile.new([ "a-very-long-document-title-that-pushes-the-hub-toggle-toward-the-right-edge-of-the-header", ".md" ])
    long_file.write("# Long")
    long_file.close

    visit open_documents_path(file_path: short_file.path)
    find(".document__hub-toggle").click
    assert_selector "#document_switcher_panel", visible: true

    short_metrics = page.evaluate_script(<<~JS)
      (() => {
        const toggle = document.querySelector(".document__hub-toggle").getBoundingClientRect()
        const panel = document.getElementById("document_switcher_panel").getBoundingClientRect()
        return { toggleLeft: toggle.left, toggleRight: toggle.right, toggleBottom: toggle.bottom, panelLeft: panel.left, panelRight: panel.right, panelTop: panel.top, viewportWidth: document.documentElement.clientWidth }
      })()
    JS

    assert_operator short_metrics["panelLeft"], :>=, 16
    assert_operator short_metrics["panelTop"], :>=, short_metrics["toggleBottom"]
    assert_operator short_metrics["panelRight"], :<=, short_metrics["viewportWidth"] - 16

    visit open_documents_path(file_path: long_file.path)
    find(".document__hub-toggle").click
    assert_selector "#document_switcher_panel", visible: true

    long_metrics = page.evaluate_script(<<~JS)
      (() => {
        const toggle = document.querySelector(".document__hub-toggle").getBoundingClientRect()
        const panel = document.getElementById("document_switcher_panel").getBoundingClientRect()
        return { toggleRight: toggle.right, panelLeft: panel.left, panelRight: panel.right, viewportWidth: document.documentElement.clientWidth }
      })()
    JS

    assert_in_delta long_metrics["toggleRight"], long_metrics["panelRight"], 2
    assert_operator long_metrics["panelLeft"], :<, long_metrics["toggleRight"]
    assert_operator long_metrics["panelLeft"], :>=, 16
    assert_operator long_metrics["panelRight"], :<=, long_metrics["viewportWidth"] - 16

    page.current_window.resize_to(375, 812)
    narrow_metrics = page.evaluate_script(<<~JS)
      (() => {
        const panel = document.getElementById("document_switcher_panel").getBoundingClientRect()
        return { panelLeft: panel.left, panelRight: panel.right, viewportWidth: document.documentElement.clientWidth }
      })()
    JS

    assert_operator narrow_metrics["panelLeft"], :>=, 16
    assert_operator narrow_metrics["panelRight"], :<=, narrow_metrics["viewportWidth"] - 16
  ensure
    page.current_window.resize_to(1400, 900)
    short_file&.unlink
    long_file&.unlink
  end
end
