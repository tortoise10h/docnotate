module Documents
  module FileSyncable
    extend ActiveSupport::Concern

    class_methods do
      def normalize_file_path(path)
        return path if path.blank?

        cleaned = path.to_s.strip
        return cleaned unless cleaned.start_with?(%r{file:}i)

        cleaned = cleaned.sub(%r{\Afile://localhost(?=/|\z)}i, "")
        cleaned = cleaned.sub(%r{\Afile://}i, "")
        cleaned = cleaned.sub(%r{\Afile:}i, "")
        cleaned = cleaned.split(/[?#]/, 2).first

        begin
          cleaned = URI.decode_uri_component(cleaned)
        rescue ArgumentError
        end

        if cleaned.match?(%r{\A/[a-zA-Z]:/})
          cleaned.sub(%r{\A/}, "")
        elsif !cleaned.start_with?("/") && !cleaned.match?(%r{\A[a-zA-Z]:})
          "/#{cleaned}"
        else
          cleaned
        end
      end

      def open(file_path)
        file_path = normalize_file_path(file_path)

        # Always work with absolute file path instead of relative
        file_path = File.expand_path(file_path)

        raise ArgumentError, "File does not exist" unless File.exist?(file_path)

        file_path = File.realpath(file_path)
        content = File.read(file_path)
        file_type = file_type_from_path(file_path)
        file_stats = File.stat(file_path)
        file_mtime = file_stats.mtime.change(nsec: file_stats.mtime.usec * 1000)

        document = find_or_initialize_by(file_path: file_path)
        current_version = document.current_version
        need_parse = document.new_record? ||
                     (current_version&.last_modified_at.present? && current_version.last_modified_at < file_mtime) ||
                     (current_version&.size.present? && current_version.size != file_stats.size)

        document.assign_attributes(
          content: content,
          file_type: file_type,
          last_opened_at: Time.current
        )

        if document.save
          metadata = AstParseable::ParseMetadata.new(size: file_stats.size, last_modified_at: file_mtime)
          document.parse_ast_and_save!(metadata: metadata) if need_parse
        end

        document
      end
    end
  end
end
