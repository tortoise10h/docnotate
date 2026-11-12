require "tempfile"

module Documents
  module FileSyncable
    extend ActiveSupport::Concern

    def browser_url
      "#{self.class.browser_base_url}/documents/open?file_path=#{ERB::Util.url_encode(file_path)}"
    end

    def save_markdown_file!(new_content)
      raise ArgumentError, "Only Markdown documents can be edited" unless markdown?
      raise ArgumentError, "Content cannot be blank" if new_content.blank?

      normalized_content = new_content.to_s.gsub("\r\n", "\n")
      return false if normalized_content == content

      dir = File.dirname(file_path)
      temp_file = Tempfile.new([ ".docnotate-", ".tmp" ], dir)
      temp_path = temp_file.path

      begin
        temp_file.binmode
        temp_file.write(normalized_content)
        temp_file.flush
        temp_file.close

        File.rename(temp_path, file_path)
      ensure
        temp_file.close unless temp_file.closed?
        File.unlink(temp_path) if File.exist?(temp_path)
      end

      file_stats = File.stat(file_path)
      file_mtime = file_stats.mtime.change(nsec: file_stats.mtime.usec * 1000)
      metadata = AstParseable::ParseMetadata.new(size: file_stats.size, last_modified_at: file_mtime)

      transaction do
        update!(content: normalized_content)
        parse_ast_and_save!(metadata: metadata)
      end

      true
    end

    class_methods do
      def browser_base_url
        if ENV["DOCNOTATE_BASE_URL"].present?
          ENV["DOCNOTATE_BASE_URL"].to_s.strip.sub(%r{/+\z}, "")
        elsif ENV["DOCNOTATE_ROOT_URL"].present?
          ENV["DOCNOTATE_ROOT_URL"].to_s.strip.sub(%r{/+\z}, "")
        elsif (db_setting = (AppSetting.get("base_url") rescue nil)).present?
          db_setting.to_s.strip.sub(%r{/+\z}, "")
        else
          "http://localhost:#{ENV.fetch('PORT', 3000)}"
        end
      end

      def resolve_document(id: nil, file_path: nil)
        if id.present? && file_path.present?
          raise ArgumentError, "Provide either file_path or document_id, not both."
        elsif id.present?
          find_by(id: id) || raise(ActiveRecord::RecordNotFound, "Document with id #{id} not found.")
        elsif file_path.present?
          open(file_path)
        else
          raise ArgumentError, "Either file_path or document_id is required."
        end
      end

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
