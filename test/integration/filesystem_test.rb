# frozen_string_literal: true

require "test_helper"
require "tmpdir"

class FilesystemTest < ActionDispatch::IntegrationTest
  test "GET /filesystem renders file tree for home directory" do
    get filesystem_path

    assert_response :success
    assert_select "turbo-frame#filesystem_tree"
    assert_select ".file-tree__content[data-controller='file-tree']"
    assert_select ".file-tree__breadcrumbs"
    assert_select ".file-tree__breadcrumb-item", text: "~"
  end

  test "GET /filesystem with custom path renders directories, files, and handles active_file_path" do
    Dir.mktmpdir do |dir|
      subdir = File.join(dir, "subfolder")
      FileUtils.mkdir_p(subdir)
      active_file = File.join(dir, "readme.md")
      File.write(active_file, "# Hello")
      File.write(File.join(dir, "script.py"), "print('hello')")

      get filesystem_path(path: dir, active_file_path: active_file, frame_id: "sidebar_tree")

      assert_response :success
      assert_select "turbo-frame#sidebar_tree"
      assert_select ".file-tree__name", text: "subfolder"
      assert_select ".file-tree__name", text: "readme.md"
      assert_select ".file-tree__name", text: "script.py"

      # Supported file has a link to open and active modifier
      assert_select "a[href=?].file-tree__item--active", open_documents_path(file_path: active_file)
      assert_select ".file-badge", text: "md"

      # Unsupported file is disabled with no link
      assert_select ".file-tree__item--disabled", text: /script\.py/
    end
  end

  test "GET /filesystem/nodes renders partial nodes list and handles empty directory" do
    Dir.mktmpdir do |dir|
      subdir = File.join(dir, "folder_a")
      FileUtils.mkdir_p(subdir)
      File.write(File.join(dir, "note.md"), "# Note")

      get nodes_filesystem_path(path: dir)

      assert_response :success
      assert_select "ul.file-tree__list"
      assert_select ".file-tree__name", text: "folder_a"
      assert_select ".file-tree__name", text: "note.md"

      # Nested empty directory renders empty hint
      get nodes_filesystem_path(path: subdir)
      assert_response :success
      assert_select ".file-tree__empty-hint", text: "Empty folder"
    end
  end

  test "GET /filesystem with invalid path returns unprocessable entity with error partial" do
    get filesystem_path(path: "/nonexistent/directory/path/12345")

    assert_response :unprocessable_entity
    assert_select "turbo-frame#filesystem_tree"
    assert_select ".file-tree__error"
    assert_select ".file-tree__error-text", text: /Directory does not exist/
  end

  test "GET /filesystem as JSON returns structured data" do
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "test.md"), "# Hi")

      get filesystem_path(path: dir), as: :json

      assert_response :success
      json = JSON.parse(response.body)
      assert_equal File.expand_path(dir), json["current_path"]
      assert_kind_of Array, json["breadcrumbs"]
      assert_kind_of Array, json["entries"]
      assert_equal "test.md", json["entries"].first["name"]
      assert_equal true, json["entries"].first["supported"]
    end
  end
end
