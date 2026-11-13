require "test_helper"

class HomeTest < ActionDispatch::IntegrationTest
  test "renders the settings button" do
    get root_path

    assert_response :success
    assert_select ".home-settings__button"
  end

  test "renders the file browser button beside the file input without loading file tree initially" do
    original_scan = Filesystem::DirectoryScanner.method(:scan)
    scanned = false
    Filesystem::DirectoryScanner.define_singleton_method(:scan) do |*args|
      scanned = true
      original_scan.call(*args)
    end

    begin
      get root_path
    ensure
      Filesystem::DirectoryScanner.define_singleton_method(:scan, original_scan)
    end

    assert_response :success
    assert_not scanned, "Filesystem::DirectoryScanner.scan should not be called on home page load"
    assert_select ".home__input-group button.home__file-tree-button[aria-label='Browse files']"
    assert_select ".home__input-group button.home__file-tree-button[data-tooltip='Browse files (⌘B)']"
    assert_select "aside.file-sidebar#home_sidebar[hidden]"
    assert_select "turbo-frame#home_sidebar_tree"
    assert_select "turbo-frame#home_sidebar_tree[src]", count: 0
  end

  test "renders the search input on the home page" do
    get root_path

    assert_response :success
    assert_select "form.home__search-toolbar[data-controller='filter'][data-turbo-frame='recent_documents'][data-turbo-action='advance']"
    assert_select "input.home__search[name='query'][placeholder='Search files'][data-action='input->filter#search']"
    assert_select "turbo-frame#recent_documents[target='_top']"
  end

  test "filters recent documents by file name as query param" do
    doc1 = create_document("project-notes.md", last_opened_at: 1.hour.ago)
    doc2 = create_document("team-sync.org", last_opened_at: 2.hours.ago)
    doc3 = create_document("release-plan.html", last_opened_at: 3.hours.ago)

    get root_path, params: { query: "sync" }

    assert_response :success
    assert_select ".recent-files__item", count: 1
    assert_select ".recent-files__name", text: doc2.display_name
    assert_select ".recent-files__name", text: doc1.display_name, count: 0
    assert_select ".recent-files__name", text: doc3.display_name, count: 0
  end

  test "filters recent documents by custom document display name" do
    doc1 = create_document("random-file.md", last_opened_at: 1.hour.ago, name: "Architecture Overview")
    doc2 = create_document("other-file.md", last_opened_at: 2.hours.ago)

    get root_path, params: { query: "Architecture" }

    assert_response :success
    assert_select ".recent-files__item", count: 1
    assert_select ".recent-files__name", text: "Architecture Overview"
    assert_select ".recent-files__name", text: doc2.display_name, count: 0
  end

  test "renders empty state when search query matches no files" do
    create_document("notes.md", last_opened_at: 1.hour.ago)

    get root_path, params: { query: "nonexistent" }

    assert_response :success
    assert_select ".recent-files__item", count: 0
    assert_select ".empty-state p", text: "No files match your search."
    assert_select "a.home__clear[href='#{root_path}']", text: "Clear"
  end

  private

  def create_document(file_path, last_opened_at: Time.current, name: nil)
    Document.create!(
      file_path: "/tmp/#{file_path}",
      content: "# #{file_path}",
      file_type: file_path.end_with?(".org") ? "org" : (file_path.end_with?(".html") ? "html" : "markdown"),
      name: name,
      last_opened_at: last_opened_at
    )
  end
end
