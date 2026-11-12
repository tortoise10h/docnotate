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
end
