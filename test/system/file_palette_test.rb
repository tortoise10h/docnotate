require "application_system_test_case"

class FilePaletteSystemTest < ApplicationSystemTestCase
  setup do
    @first = Tempfile.new([ "palette-alpha", ".md" ])
    @first.write("# Alpha document")
    @first.close

    @second = Tempfile.new([ "palette-beta", ".md" ])
    @second.write("# Beta document")
    @second.close

    @first_doc = Document.open(@first.path)
    @first_doc.update!(last_opened_at: 10.minutes.ago)
    @second_doc = Document.open(@second.path)
    @second_doc.update!(last_opened_at: 2.minutes.ago)
  end

  teardown do
    @first.unlink
    @second.unlink
  end

  test "opens with Cmd+K on home page, filters by name, opens with Enter, and works on document page" do
    visit root_path

    assert_selector ".file-palette__hotkey-hint[aria-keyshortcuts='Meta+K Control+K']", text: /⌘k/i

    send_palette_shortcut
    assert_selector "#file_palette_dialog", visible: true
    assert_equal "file_palette_input", page.evaluate_script("document.activeElement.id")
    assert_selector "#file_palette_list [role='option']", count: 2

    # Pressing Escape closes and returns focus
    find("#file_palette_input").send_keys(:escape)
    assert_no_selector "#file_palette_dialog", visible: true
    assert_equal "file_path", page.evaluate_script("document.activeElement.id")

    # Pressing Cmd+K again while open closes it
    send_palette_shortcut
    assert_selector "#file_palette_dialog", visible: true
    send_palette_shortcut
    assert_no_selector "#file_palette_dialog", visible: true

    # Clicking outside closes it
    send_palette_shortcut
    assert_selector "#file_palette_dialog", visible: true
    find(".file-palette__backdrop").click
    assert_no_selector "#file_palette_dialog", visible: true

    # Re-open, search, navigate with keyboard, open with Enter
    send_palette_shortcut
    find("#file_palette_input").fill_in with: "palette-alpha"
    assert_selector "#file_palette_list [role='option']", count: 1
    assert_selector ".file-palette__match", text: "palette-alpha"

    # Empty state when nothing matches
    find("#file_palette_input").fill_in with: "no-such-file-xyz"
    assert_selector ".file-palette__empty", text: 'No files matching "no-such-file-xyz"'

    # Clear query restores recent list, then filter and open with Enter
    find("#file_palette_input").fill_in with: ""
    assert_selector "#file_palette_list [role='option']", count: 2

    find("#file_palette_input").fill_in with: "palette-alpha"
    assert_selector "#file_palette_list [role='option']", count: 1
    find("#file_palette_input").send_keys(:enter)

    assert_selector ".document__title", text: @first_doc.display_name
    assert_no_selector "#file_palette_dialog", visible: true

    # Works while viewing a document (even with comments present)
    @first_doc.current_version.comments.create!(content: "Sample comment")
    visit open_documents_path(file_path: @first.path)
    send_palette_shortcut
    assert_selector "#file_palette_dialog", visible: true
    find("#file_palette_input").send_keys(:arrow_down)
    find("#file_palette_input").send_keys(:enter)

    assert_selector ".document__title", text: @second_doc.display_name
  end

  test "works over an HTML document iframe and in dark theme" do
    html_file = Tempfile.new([ "palette-html", ".html" ])
    html_file.write("<h1>HTML report</h1>")
    html_file.close

    visit open_documents_path(file_path: html_file.path)
    assert_selector "iframe.html-viewer__frame"

    page.execute_script("document.documentElement.setAttribute('data-theme', 'dark')")
    send_palette_shortcut
    assert_selector "#file_palette_dialog", visible: true

    find("#file_palette_input").fill_in with: "palette-alpha"
    assert_selector "#file_palette_list [role='option']", count: 1
    find("#file_palette_input").send_keys(:enter)

    assert_selector ".document__title", text: @first_doc.display_name
  ensure
    html_file&.unlink
  end

  private

  def send_palette_shortcut
    # Dispatch keyboard event using the platform's Mod key so Selenium doesn't swallow OS-level Meta+K
    page.execute_script(<<~JS)
      const isMac = /Mac|iPod|iPhone|iPad/i.test(navigator.platform)
      const target = document.activeElement || document.body
      target.dispatchEvent(new KeyboardEvent("keydown", {
        key: "k",
        code: "KeyK",
        metaKey: isMac,
        ctrlKey: !isMac,
        bubbles: true,
        cancelable: true
      }))
    JS
  end
end
