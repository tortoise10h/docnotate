require "application_system_test_case"

class OrgEditorTest < ApplicationSystemTestCase
  setup do
    @initial_org = "* Initial Org Heading\n\nInitial paragraph with *bold* text."
    @file = Tempfile.new([ "editable-org", ".org" ])
    @file.write(@initial_org)
    @file.close
  end

  teardown do
    @file.unlink
  end

  test "toggles plain textarea editor for org files, saves to disk, and bumps version" do
    visit open_documents_path(file_path: @file.path)

    assert_selector ".document__version", text: "v1"
    edit_button = find("button[aria-label='Edit org file']")
    assert_equal "Edit org file (⌘⇧E)", edit_button["data-tooltip"]

    edit_button.click

    assert_selector ".document__markdown-editor", visible: true
    assert_selector "textarea.document__plain-editor[aria-label='Edit org file source']", visible: true
    assert_no_selector ".document__markdown-editor-container"
    assert_no_selector ".overtype-container"

    textarea = find("textarea.document__plain-editor")
    assert_equal @initial_org, textarea.value

    updated_org = "* Updated Org Heading\n\n- First item\n- Second item"
    textarea.fill_in(with: updated_org)

    find(".document__markdown-editor-actions button", text: "Save").click
    assert_selector ".document__save-dialog[open]"
    assert_text File.realpath(@file.path)

    find(".document__save-dialog button", text: "Save to disk").click

    assert_selector ".document__version", text: "v2"
    assert_equal updated_org, File.read(@file.path)
    assert_selector "h1", text: "Updated Org Heading"
  end

  test "canceling plain org editor reverts content and exits edit mode" do
    visit open_documents_path(file_path: @file.path)

    find("button[aria-label='Edit org file']").click
    textarea = find("textarea.document__plain-editor")
    textarea.fill_in(with: "* Discarded Heading")

    find(".document__markdown-editor-actions button", text: "Cancel").click

    assert_no_selector ".document__markdown-editor", visible: true
    assert_selector ".document__content", visible: true
    assert_selector "h1", text: "Initial Org Heading"
    assert_equal @initial_org, File.read(@file.path)

    # Re-opening confirms the unsaved draft was reverted
    find("button[aria-label='Edit org file']").click
    assert_equal @initial_org, find("textarea.document__plain-editor").value
  end

  test "keyboard shortcuts Escape cancels and Mod+Enter opens save dialog in plain org editor" do
    visit open_documents_path(file_path: @file.path)

    find("button[aria-label='Edit org file']").click
    textarea = find("textarea.document__plain-editor")
    textarea.fill_in(with: "* Keyboard Edit")

    mod_key = page.evaluate_script("navigator.platform.toUpperCase().indexOf('MAC') >= 0") ? :meta : :control
    textarea.send_keys([ mod_key, :enter ])
    assert_selector ".document__save-dialog[open]"

    find(".document__save-dialog button", text: "Cancel").click
    assert_no_selector ".document__save-dialog[open]"

    textarea.send_keys(:escape)
    assert_no_selector ".document__markdown-editor", visible: true
    assert_equal @initial_org, File.read(@file.path)
  end

  test "copy raw org button copies raw source without embedding it in button attribute and surfaces failure" do
    visit open_documents_path(file_path: @file.path)

    copy_button = find("button[aria-label='Copy raw org']")
    assert_equal "Copy raw org", copy_button["data-tooltip"]
    assert_nil copy_button["data-clipboard-text-value"]

    page.execute_script(<<~JS)
      window.__copiedText = null
      Object.defineProperty(navigator, "clipboard", {
        configurable: true,
        value: {
          writeText: async (text) => { window.__copiedText = text }
        }
      })
    JS

    copy_button.click

    assert_selector "button[aria-label='Copied!'][data-tooltip='Copied!']"
    assert_equal @initial_org, page.evaluate_script("window.__copiedText")

    # Verify clipboard failure surfaces feedback rather than a silent no-op
    page.execute_script(<<~JS)
      Object.defineProperty(navigator, "clipboard", {
        configurable: true,
        value: {
          writeText: async () => { throw new Error("Permission denied") }
        }
      })
    JS

    find("button[data-clipboard-source-selector-value='#document_source_content']").click
    assert_selector "button[aria-label='Copy failed'][data-tooltip='Copy failed'].document__copy-button--error"
  end
end
