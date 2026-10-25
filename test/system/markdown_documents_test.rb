require "application_system_test_case"

class MarkdownDocumentsSystemTest < ApplicationSystemTestCase
  setup do
    @file = Tempfile.new([ "wide-markdown", ".md" ])
    @file.write(<<~MARKDOWN)
      # Release overview

      Prose remains a comfortable reading width while tables and diagrams can use the surrounding space.

      - Review the release checklist.
      - Keep annotations beside their source.

      > The reading column also applies to quotations.

      | Status | Owner |
      | --- | --- |
      | Ready | Platform |

      | Service | Owner | Region | Status | Latency | Traffic | Errors | Capacity | Version | Decision |
      | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
      | Gateway | Platform | Europe | Ready | 42 ms | 1200 rpm | 0.02% | 65% | 3.8.1 | Approved |

      ```mermaid
      flowchart LR
        A[Client request] --> B[Edge gateway] --> C[Authentication] --> D[Request routing] --> E[Background worker] --> F[Persistent storage] --> G[Audit reporting]
      ```

      ```mermaid
      flowchart TD
        A[Review] --> B[Approve]
      ```
    MARKDOWN
    @file.close
  end

  teardown do
    @file.unlink
  end

  test "reading view is the default and wide view expands blocks without widening prose" do
    page.current_window.resize_to(1440, 1000)
    visit open_documents_path(file_path: @file.path)
    assert_selector ".document__mermaid-canvas > svg", count: 2

    reading_width = find("#document_paper").rect.width
    assert_operator reading_width, :<, 900
    assert_selector "button[aria-label='Wide view'][aria-pressed='false']"
    find("button[aria-label='Wide view']").click
    assert_selector "button[aria-label='Wide view'][aria-pressed='true']"
    assert_operator find("#document_paper").rect.width, :>, 1200

    prose = first(".document__content > p").rect
    assert_operator prose.width, :<=, 700
    assert_in_delta page.evaluate_script("document.documentElement.clientWidth / 2"), prose.x + prose.width / 2, 2
    assert_operator all("table")[0].rect.width, :<, prose.width
    assert_operator all("table")[1].rect.width, :>, prose.width * 1.5
    assert_operator all(".document__mermaid-canvas > svg")[0].rect.width, :>, prose.width * 1.5
    assert_operator all(".document__mermaid-canvas > svg")[1].rect.width, :<, prose.width

    find("button[aria-label='Wide view']").send_keys(:space)
    assert_selector "button[aria-label='Wide view'][aria-pressed='false']"
    assert_in_delta reading_width, find("#document_paper").rect.width, 1
    find("button[aria-label='Wide view']").click

    [ 900, 390 ].each do |width|
      page.current_window.resize_to(width, 1000)
      assert_equal width, page.evaluate_script("window.innerWidth")
      assert_no_horizontal_page_overflow
      assert_operator first(".document__content > p").rect.width, :<=, 700
      assert page.evaluate_script("document.querySelectorAll('table')[1].scrollWidth > document.querySelectorAll('table')[1].clientWidth")
      all(".document__mermaid-canvas > svg").each do |diagram|
        assert_operator diagram.rect.x + diagram.rect.width, :<=, width
      end
    end

    find("button[aria-label='Wide view']").click
    assert_no_horizontal_page_overflow
    find("button[aria-label='Wide view']").click
    assert_selector "button[aria-label='Wide view'][aria-pressed='true']"
    refresh
    assert_selector "button[aria-label='Wide view'][aria-pressed='false']"
  end

  test "comments on the right edge of a wide table remain accessible and anchored" do
    page.current_window.resize_to(1440, 1000)
    visit open_documents_path(file_path: @file.path)
    assert_selector ".document__mermaid-canvas > svg", count: 2
    find("button[aria-label='Wide view']").click

    page.execute_script(<<~JS)
      const table = document.querySelectorAll("table")[1]
      table.scrollLeft = table.scrollWidth
      const cell = table.querySelector("tbody td:last-child")
      const walker = document.createTreeWalker(cell, NodeFilter.SHOW_TEXT)
      let text
      while ((text = walker.nextNode()) && !text.textContent.includes("Approved")) {}
      const range = document.createRange()
      const start = text.textContent.indexOf("Approved")
      range.setStart(text, start)
      range.setEnd(text, start + "Approved".length)
      window.getSelection().removeAllRanges()
      window.getSelection().addRange(range)
      cell.dispatchEvent(new MouseEvent("mouseup", { bubbles: true }))
    JS
    assert_selector ".document__selection-toolbar"
    assert_no_horizontal_page_overflow
    click_button "Add Note"
    assert_selector ".document__comment-card"
    card = find(".document__comment-card").rect
    assert_operator card.x + card.width, :<=, 1440
    fill_in "comment_create_text", with: "Confirm the final approval."
    within ".document__comment-card" do
      click_button "Comment"
    end
    assert_selector "td:last-child .document__comment-highlight", text: "Approved"

    refresh
    assert_selector "td:last-child .document__comment-highlight", text: "Approved", visible: :all
    find("button[aria-label='Wide view']").click
    [ 1440, 390 ].each do |width|
      page.current_window.resize_to(width, 1000)
      page.execute_script("const table = document.querySelectorAll('table')[1]; table.scrollLeft = table.scrollWidth")
      page.execute_script("document.querySelector('td:last-child .document__comment-highlight').scrollIntoView({ block: 'center' })")
      find("td:last-child .document__comment-highlight").click
      assert_selector ".document__comment-popover", text: "Confirm the final approval."
      popover = find(".document__comment-popover").rect
      assert_operator popover.x, :>=, 0
      assert_operator popover.x + popover.width, :<=, width
      assert_no_horizontal_page_overflow
      find(".document__comment-popover button[aria-label='Close']").click
    end
  end

  test "toggles between document content and previous comments" do
    visit open_documents_path(file_path: @file.path)
    document = Document.find_by!(file_path: File.realpath(@file.path))
    first_version = document.current_version
    first_version.comments.create!(content: "Note from previous version")

    @file.open
    @file.write("# Updated Overview\n\nNew paragraph content.")
    @file.close

    visit open_documents_path(file_path: @file.path)

    assert_selector ".document__content", visible: true
    assert_selector ".document__archived-panel", visible: false

    find(".document__comment-inbox-button").click

    assert_selector ".document__comment-inbox-button[aria-pressed='true'][aria-label='Back to document']"
    assert_selector ".document__content", visible: false
    assert_selector ".document__archived-panel", visible: true
    assert_text "Note from previous version"

    find(".document__comment-inbox-button").click

    assert_selector ".document__comment-inbox-button[aria-pressed='false'][aria-label='Previous comments']"
    assert_selector ".document__content", visible: true
    assert_selector ".document__archived-panel", visible: false
  end

  private

  def assert_no_horizontal_page_overflow
    assert page.evaluate_script("document.documentElement.scrollWidth <= document.documentElement.clientWidth")
  end
end
