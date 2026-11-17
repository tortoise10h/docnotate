require "application_system_test_case"

class MarkdownEditorTest < ApplicationSystemTestCase
  setup do
    @file = Tempfile.new([ "editable-markdown", ".md" ])
    @file.write("# Initial Heading\n\nInitial paragraph text.")
    @file.close
  end

  teardown do
    @file.unlink
  end

  test "clicking edit enters edit mode, cancel dialog writes nothing, confirm persists and bumps version" do
    visit open_documents_path(file_path: @file.path)

    assert_selector ".document__version", text: "v1"
    assert_selector "button[aria-label='Edit markdown']"

    # Enter edit mode
    find("button[aria-label='Edit markdown']").click

    assert_selector ".document__markdown-editor", visible: true
    assert_selector ".document__markdown-editor-container"

    # Type new content in OverType's textarea
    textarea = find(".overtype-input")
    textarea.fill_in(with: "# Brand New Heading\n\nBrand new content.")

    # Click Save in the editor bar
    find(".document__markdown-editor-actions button", text: "Save").click

    # Dialog opens, warning names the file path
    assert_selector ".document__save-dialog[open]"
    assert_text File.realpath(@file.path)

    # Cancel dialog
    find(".document__save-dialog button", text: "Cancel").click

    # Dialog is closed, disk remains unchanged, version remains v1
    assert_no_selector ".document__save-dialog[open]"
    assert_equal "# Initial Heading\n\nInitial paragraph text.", File.read(@file.path)
    assert_selector ".document__version", text: "v1"

    # Click Save again
    find(".document__markdown-editor-actions button", text: "Save").click
    assert_selector ".document__save-dialog[open]"

    # Confirm save to disk
    find(".document__save-dialog button", text: "Save to disk").click

    # Page refreshes with v2 and new content
    assert_selector ".document__version", text: "v2"
    assert_equal "# Brand New Heading\n\nBrand new content.", File.read(@file.path)
    assert_selector "h1", text: "Brand New Heading"
  end

  test "canceling from editor bar reverts content and exits edit mode" do
    visit open_documents_path(file_path: @file.path)

    find("button[aria-label='Edit markdown']").click
    assert_selector ".document__markdown-editor", visible: true

    textarea = find(".overtype-input")
    textarea.fill_in(with: "# Temporary edits")

    find(".document__markdown-editor-actions button", text: "Cancel").click

    assert_no_selector ".document__markdown-editor", visible: true
    assert_selector ".document__content", visible: true
    assert_selector "h1", text: "Initial Heading"
    assert_equal "# Initial Heading\n\nInitial paragraph text.", File.read(@file.path)
  end

  test "clicking edit button toggles between edit mode and read-only mode" do
    visit open_documents_path(file_path: @file.path)

    edit_button = find("button[aria-label='Edit markdown']")
    assert_equal "false", edit_button["aria-pressed"]
    assert_no_selector ".icon-button--active"

    # Click to enter edit mode
    edit_button.click
    assert_selector ".document__markdown-editor", visible: true
    assert_equal "true", edit_button["aria-pressed"]
    assert_selector "button[aria-label='Edit markdown'].icon-button--active"

    # Click again to exit back to read-only mode
    edit_button.click
    assert_no_selector ".document__markdown-editor", visible: true
    assert_selector ".document__content", visible: true
    assert_equal "false", edit_button["aria-pressed"]
    assert_no_selector "button[aria-label='Edit markdown'].icon-button--active"
  end

  test "copy document text in hub dropdown copies raw markdown and live OverType edits without a header button" do
    visit open_documents_path(file_path: @file.path)

    assert_no_selector ".document__actions button[data-controller~='clipboard']"

    page.execute_script(<<~JS)
      window.__copiedText = null
      Object.defineProperty(navigator, "clipboard", {
        configurable: true,
        value: {
          writeText: async (text) => { window.__copiedText = text }
        }
      })
    JS

    find("button[aria-label='Switch file']").click
    find("#document_switcher_panel .document__hub-actions button[aria-label='Copy document text']").click
    assert_selector "#document_switcher_panel .document__hub-actions button[aria-label='Copied!']", text: "Copied!"
    assert_equal "# Initial Heading\n\nInitial paragraph text.", page.evaluate_script("window.__copiedText")

    # Close dropdown, open OverType editor, edit without saving, and copy live draft
    find("button[aria-label='Switch file']").click
    find("button[aria-label='Edit markdown']").click
    dirty_md = "# Unsaved Markdown\n\nLive edit."
    find(".overtype-input").fill_in(with: dirty_md)

    find("button[aria-label='Switch file']").click
    find("#document_switcher_panel .document__hub-actions button[data-clipboard-source-selector-value='#document_source_content']").click
    assert_equal dirty_md, page.evaluate_script("window.__copiedText")
  end
end
