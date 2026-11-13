require "test_helper"

class Documents::FileTypeableTest < ActiveSupport::TestCase
  test "maps html and htm extensions to the html file type" do
    assert_equal "html", Document.file_type_from_path("/notes/report.html")
    assert_equal "html", Document.file_type_from_path("/notes/REPORT.HTM")
  end

  test "maps org extension to the org file type" do
    assert_equal "org", Document.file_type_from_path("/notes/report.org")
    assert_equal "org", Document.file_type_from_path("/notes/REPORT.ORG")
    assert Document.org_file?("/notes/report.org")
    assert Document.new(file_type: "org").org?
  end

  test "supports markdown, html, and org files but not other types" do
    assert Document.supported_file?("/notes/plan.md")
    assert Document.supported_file?("/notes/page.html")
    assert Document.supported_file?("/notes/todo.org")
    assert Document.supported_file?("file:///notes/todo.org#section")
    assert_equal "org", Document.file_type_from_path("file:///notes/todo.org")
    assert_not Document.supported_file?("/notes/notes.txt")
    assert_not Document.supported_file?("/notes/report.pdf")
  end
end
