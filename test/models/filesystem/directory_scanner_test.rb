# frozen_string_literal: true

require "test_helper"
require "tmpdir"

module Filesystem
  class DirectoryScannerTest < ActiveSupport::TestCase
    test "scans directory and separates directories and files" do
      Dir.mktmpdir do |dir|
        # Create subdirectories
        subdir1 = File.join(dir, "beta_dir")
        subdir2 = File.join(dir, "alpha_dir")
        FileUtils.mkdir_p(subdir1)
        FileUtils.mkdir_p(subdir2)

        # Create files
        File.write(File.join(dir, "doc.md"), "# Hello")
        File.write(File.join(dir, "page.html"), "<h1>Page</h1>")
        File.write(File.join(dir, "code.rb"), "puts 'hi'")
        File.write(File.join(dir, ".hidden"), "secret")

        result = DirectoryScanner.scan(dir)

        assert_equal File.expand_path(dir), result.current_path
        assert_not_nil result.parent_path
        assert_kind_of Array, result.breadcrumbs

        # Hidden file should be excluded
        names = result.entries.map(&:name)
        assert_not_includes names, ".hidden"

        # Directories first (sorted alphabetically)
        assert_equal "alpha_dir", result.entries[0].name
        assert result.entries[0].directory?
        assert_not result.entries[0].supported?

        assert_equal "beta_dir", result.entries[1].name
        assert result.entries[1].directory?

        # Files second (sorted alphabetically)
        assert_equal "code.rb", result.entries[2].name
        assert_not result.entries[2].directory?
        assert_not result.entries[2].supported?
        assert_nil result.entries[2].file_type

        assert_equal "doc.md", result.entries[3].name
        assert_not result.entries[3].directory?
        assert result.entries[3].supported?
        assert_equal "markdown", result.entries[3].file_type

        assert_equal "page.html", result.entries[4].name
        assert_not result.entries[4].directory?
        assert result.entries[4].supported?
        assert_equal "html", result.entries[4].file_type
      end
    end

    test "detects whether directory has visible children" do
      Dir.mktmpdir do |dir|
        empty_dir = File.join(dir, "empty")
        FileUtils.mkdir_p(empty_dir)

        non_empty_dir = File.join(dir, "non_empty")
        FileUtils.mkdir_p(non_empty_dir)
        File.write(File.join(non_empty_dir, "file.txt"), "hello")

        only_hidden_dir = File.join(dir, "only_hidden")
        FileUtils.mkdir_p(only_hidden_dir)
        File.write(File.join(only_hidden_dir, ".hidden"), "hidden")

        result = DirectoryScanner.scan(dir)
        entries_by_name = result.entries.index_by(&:name)

        assert_equal false, entries_by_name["empty"].has_children
        assert_equal true, entries_by_name["non_empty"].has_children
        assert_equal false, entries_by_name["only_hidden"].has_children
      end
    end

    test "raises ScanError when directory does not exist" do
      assert_raises(DirectoryScanner::ScanError) do
        DirectoryScanner.scan("/path/that/definitely/does/not/exist_12345")
      end
    end

    test "raises ScanError when path is a file, not a directory" do
      Dir.mktmpdir do |dir|
        file_path = File.join(dir, "test.txt")
        File.write(file_path, "content")

        assert_raises(DirectoryScanner::ScanError) do
          DirectoryScanner.scan(file_path)
        end
      end
    end

    test "defaults to Dir.home when path is blank" do
      result = DirectoryScanner.scan("")
      assert_equal File.expand_path(Dir.home), result.current_path
      assert_equal "~", result.breadcrumbs.first[:name]
    end

    test "breadcrumbs correctly format root and subdirectories" do
      root_result = DirectoryScanner.scan("/")
      assert_equal "/", root_result.breadcrumbs.first[:name]
      assert_equal "/", root_result.breadcrumbs.first[:path]
      assert_nil root_result.parent_path

      home_path = File.expand_path(Dir.home)
      home_result = DirectoryScanner.scan(home_path)
      assert_equal 1, home_result.breadcrumbs.length
      assert_equal "~", home_result.breadcrumbs.first[:name]
      assert_equal home_path, home_result.breadcrumbs.first[:path]
    end
  end
end
