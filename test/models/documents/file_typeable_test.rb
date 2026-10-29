require "test_helper"

class Documents::FileTypeableTest < ActiveSupport::TestCase
  test "maps html and htm extensions to the html file type" do
    assert_equal "html", Document.file_type_from_path("/notes/report.html")
    assert_equal "html", Document.file_type_from_path("/notes/REPORT.HTM")
  end

  test "supports markdown and html files but not other types" do
    assert Document.supported_file?("/notes/plan.md")
    assert Document.supported_file?("/notes/page.html")
    assert Document.supported_file?("file:///notes/page.html#section")
    assert_equal "html", Document.file_type_from_path("file:///notes/page.html")
    assert_not Document.supported_file?("/notes/notes.txt")
    assert_not Document.supported_file?("/notes/report.pdf")
  end
end
