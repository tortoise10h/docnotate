module Documents
  module FileSyncable
    extend ActiveSupport::Concern

    class_methods do
      def open(file_path)
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
