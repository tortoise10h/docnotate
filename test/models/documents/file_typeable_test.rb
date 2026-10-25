require "test_helper"

class Documents::FileTypeableTest < ActiveSupport::TestCase
  test "maps html and htm extensions to the html file type" do
    assert_equal "html", Document.file_type_from_path("/notes/report.html")
    assert_equal "html", Document.file_type_from_path("/notes/REPORT.HTM")
  end

  test "maps json extension to the json file type" do
    assert_equal "json", Document.file_type_from_path("/notes/config.json")
    assert_equal "json", Document.file_type_from_path("/notes/DATA.JSON")
  end

  test "supports markdown, html, and json files but not other types" do
    assert Document.supported_file?("/notes/plan.md")
    assert Document.supported_file?("/notes/page.html")
    assert Document.supported_file?("/notes/config.json")
    assert_not Document.supported_file?("/notes/notes.txt")
    assert_not Document.supported_file?("/notes/report.pdf")
  end
end
