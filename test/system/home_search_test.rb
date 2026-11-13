require "application_system_test_case"

class HomeSearchSystemTest < ApplicationSystemTestCase
  test "user can filter documents by name as they type" do
    doc1 = Document.create!(
      file_path: "/tmp/sys-notes.md",
      content: "# Notes",
      file_type: "markdown",
      last_opened_at: 10.minutes.ago
    )
    doc2 = Document.create!(
      file_path: "/tmp/sys-plan.md",
      content: "# Plan",
      file_type: "markdown",
      last_opened_at: 5.minutes.ago
    )

    visit root_path

    assert_selector ".recent-files__item", text: "sys-notes.md"
    assert_selector ".recent-files__item", text: "sys-plan.md"

    # Filter as user types
    fill_in "Search files", with: "plan"

    assert_selector ".recent-files__item", text: "sys-plan.md"
    assert_no_selector ".recent-files__item", text: "sys-notes.md"

    # Search non-matching term
    fill_in "Search files", with: "unknown"

    assert_selector ".empty-state", text: "No files match your search."
    assert_no_selector ".recent-files__item"

    # Clear input
    fill_in "Search files", with: ""

    assert_selector ".recent-files__item", text: "sys-notes.md"
    assert_selector ".recent-files__item", text: "sys-plan.md"
  end
end
