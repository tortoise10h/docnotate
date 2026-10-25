require "test_helper"

class Documents::FilterableTest < ActiveSupport::TestCase
  setup do
    @markdown = Document.create!(file_path: "/notes/plan.md", content: "# Plan", file_type: "markdown")
    @html = Document.create!(file_path: "/notes/landing.html", content: "<h1>Hi</h1>", file_type: "html")
    @json = Document.create!(file_path: "/notes/config.json", content: '{"ok": true}', file_type: "json")
    @renamed = Document.create!(file_path: "/notes/old-name.md", name: "Team Retro", content: "# Retro", file_type: "markdown")
  end

  test "matching_title finds custom names and file paths, ignoring case" do
    assert_includes Document.matching_title("retro"), @renamed
    assert_includes Document.matching_title("LANDING"), @html
    assert_not_includes Document.matching_title("retro"), @markdown
  end

  test "matching_title with a blank query returns everything" do
    assert_equal 4, Document.matching_title(nil).count
    assert_equal 4, Document.matching_title("  ").count
  end

  test "with_file_type filters by type and ignores unknown values" do
    assert_equal [@markdown, @renamed].map(&:id).sort, Document.with_file_type("markdown").ids.sort
    assert_equal [@html.id], Document.with_file_type("html").ids
    assert_equal [@json.id], Document.with_file_type("json").ids
    assert_equal 4, Document.with_file_type("pdf").count
    assert_equal 4, Document.with_file_type(nil).count
  end
end
