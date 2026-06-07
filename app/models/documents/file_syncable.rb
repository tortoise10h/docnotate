module Documents
  module FileSyncable
    extend ActiveSupport::Concern

    class_methods do
      def open(file_path)
        raise ArgumentError "File does not exist" unless File.exist?(file_path)

        content = File.read(file_path)
        file_type = file_type_from_path(file_path)
        file_stats = File.stat(file_path)

        document = find_or_initialize_by(file_path: file_path)
        need_parse = document.new_record? ||
                     (document.last_modified_at.present? && document.last_modified_at < file_stats.mtime) ||
                     (document.size.present? && document.size != file_stats.size)
        version = need_parse ? document.next_version : (document.version || "v1")

        document.assign_attributes(
          content: content,
          file_type: file_type,
          size: file_stats.size,
          last_modified_at: file_stats.mtime,
          last_opened_at: Time.current,
          version:
        )

        if document.save
          document.parse_ast_and_save! if need_parse
        end

        document
      end
    end
  end
end
