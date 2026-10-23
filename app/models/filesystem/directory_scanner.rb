# frozen_string_literal: true

module Filesystem
  class DirectoryScanner
    class ScanError < StandardError; end

    Entry = Data.define(:name, :path, :is_directory, :has_children, :supported, :file_type) do
      def directory?
        is_directory
      end

      def supported?
        supported
      end
    end

    Result = Data.define(:current_path, :parent_path, :breadcrumbs, :entries)

    def self.scan(path = nil)
      new(path).scan
    end

    def initialize(path = nil)
      @raw_path = path.presence || Dir.home
    end

    def scan
      expanded_path = File.expand_path(@raw_path)

      unless File.exist?(expanded_path)
        raise ScanError, "Directory does not exist: #{expanded_path}"
      end

      unless File.directory?(expanded_path)
        raise ScanError, "Path is not a directory: #{expanded_path}"
      end

      entries = []
      begin
        Dir.children(expanded_path).each do |child_name|
          next if child_name.start_with?(".")

          child_path = File.join(expanded_path, child_name)
          is_dir = begin
            File.directory?(child_path)
          rescue SystemCallError
            false
          end

          has_children = false
          supported = false
          file_type = nil

          if is_dir
            begin
              has_children = Dir.children(child_path).any? { |c| !c.start_with?(".") }
            rescue SystemCallError
              has_children = false
            end
          else
            supported = Document.supported_file?(child_path)
            file_type = Document.file_type_from_path(child_path) if supported
          end

          entries << Entry.new(
            name: child_name,
            path: child_path,
            is_directory: is_dir,
            has_children: has_children,
            supported: supported,
            file_type: file_type
          )
        end
      rescue SystemCallError => e
        raise ScanError, "Unable to access directory: #{e.message}"
      end

      sorted_entries = entries.sort_by do |entry|
        [entry.is_directory ? 0 : 1, entry.name.downcase]
      end

      parent = if expanded_path == "/"
                 nil
               else
                 File.dirname(expanded_path)
               end

      Result.new(
        current_path: expanded_path,
        parent_path: parent,
        breadcrumbs: build_breadcrumbs(expanded_path),
        entries: sorted_entries
      )
    end

    private

    def build_breadcrumbs(path)
      home = File.expand_path(Dir.home)
      normalized_path = begin
        File.realpath(path)
      rescue StandardError
        path
      end

      if normalized_path == home
        [{ name: "~", path: home }]
      elsif normalized_path.start_with?(home + "/")
        relative = normalized_path.delete_prefix(home + "/")
        segments = relative.split("/")
        crumbs = [{ name: "~", path: home }]
        current = home
        segments.each do |segment|
          current = File.join(current, segment)
          crumbs << { name: segment, path: current }
        end
        crumbs
      else
        crumbs = [{ name: "/", path: "/" }]
        segments = normalized_path.split("/").reject(&:empty?)
        current = ""
        segments.each do |segment|
          current = "#{current}/#{segment}"
          crumbs << { name: segment, path: current }
        end
        crumbs
      end
    end
  end
end
