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
end
