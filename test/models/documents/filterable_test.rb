require "test_helper"

class Documents::FilterableTest < ActiveSupport::TestCase
  setup do
    @markdown = Document.create!(file_path: "/notes/plan.md", content: "# Plan", file_type: "markdown")
    @html = Document.create!(file_path: "/notes/landing.html", content: "<h1>Hi</h1>", file_type: "html")
    @org = Document.create!(file_path: "/notes/agenda.org", content: "* Agenda", file_type: "org")
    @renamed = Document.create!(file_path: "/notes/old-name.md", name: "Team Retro", content: "# Retro", file_type: "markdown")
  end

  test "matching_title finds custom names and file paths, ignoring case" do
    assert_includes Document.matching_title("retro"), @renamed
    assert_includes Document.matching_title("LANDING"), @html
    assert_includes Document.matching_title("agenda"), @org
    assert_not_includes Document.matching_title("retro"), @markdown
  end

  test "matching_title with a blank query returns everything" do
    assert_equal 4, Document.matching_title(nil).count
    assert_equal 4, Document.matching_title("  ").count
  end

  test "with_file_type filters by type and ignores unknown values" do
    assert_equal [@markdown, @renamed].map(&:id).sort, Document.with_file_type("markdown").ids.sort
    assert_equal [@html.id], Document.with_file_type("html").ids
    assert_equal [@org.id], Document.with_file_type("org").ids
    assert_equal 4, Document.with_file_type("pdf").count
    assert_equal 4, Document.with_file_type(nil).count
  end

  test "matching_title treats space, hyphen, underscore, dot, and slash as equivalent separators" do
    palette_doc = Document.create!(
      file_path: "/docs/guides/how-file-search-palette-works.html",
      content: "<h1>Palette</h1>",
      file_type: "html"
    )

    assert_includes Document.matching_title("how file"), palette_doc
    assert_includes Document.matching_title("how-file"), palette_doc
    assert_includes Document.matching_title("how_file"), palette_doc
    assert_includes Document.matching_title("works.html"), palette_doc
    assert_includes Document.matching_title("guides/how"), palette_doc
  end

  test "matching_title requires all tokens regardless of order and returns empty when unmatched" do
    palette_doc = Document.create!(
      file_path: "/docs/how-file-search-palette-works.html",
      content: "<h1>Palette</h1>",
      file_type: "html"
    )

    assert_includes Document.matching_title("works palette"), palette_doc
    assert_includes Document.matching_title("palette works"), palette_doc
    assert_includes Document.matching_title("notes agenda"), @org
    assert_empty Document.matching_title("palette nonexistent")
  end

  test "matching_title treats percent literally and does not treat bare underscore as a wildcard" do
    percent_doc = Document.create!(file_path: "/notes/100%-done.md", content: "# Done", file_type: "markdown")

    assert_equal [ percent_doc ], Document.matching_title("%").to_a
    assert_equal [ percent_doc ], Document.matching_title("100%").to_a
    assert_empty Document.matching_title("_")
    assert_empty Document.matching_title("___")
  end

  test "search_by_title returns none for blank queries and ranks stronger display matches first" do
    assert_empty Document.search_by_title("   ")

    path_only = Document.create!(
      file_path: "/docs/how-to/guide.md",
      content: "# Guide",
      file_type: "markdown",
      last_opened_at: 1.minute.ago
    )
    contains_match = Document.create!(
      file_path: "/docs/callouts-showcase.md",
      content: "# Showcase",
      file_type: "markdown",
      last_opened_at: 2.minutes.ago
    )
    prefix_match = Document.create!(
      file_path: "/docs/how-file-search-palette-works.html",
      content: "<h1>How</h1>",
      file_type: "html",
      last_opened_at: 10.minutes.ago
    )

    assert_equal [ prefix_match, contains_match, path_only ], Document.search_by_title("how").to_a
  end
end
