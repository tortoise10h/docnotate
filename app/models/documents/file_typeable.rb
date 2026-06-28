module Documents
  module FileTypeable
    extend ActiveSupport::Concern

    FILE_TYPES = %w[markdown text pdf].freeze

    FILE_TYPES.each do |type|
      define_method("#{type}?") { file_type == type }
    end

    def file_type_from_path
      self.class.file_type_from_path(file_path)
    end

    class_methods do
      MARKDOWN_EXTENSIONS = %w[.md .markdown .mdx].freeze

      def file_type_from_path(file_path)
        ext = File.extname(file_path).downcase
        case ext
        when *MARKDOWN_EXTENSIONS
          "markdown"
        when ".txt"
          "text"
        else
          "markdown"
        end
      end

      def markdown_file?(file_path)
        MARKDOWN_EXTENSIONS.include?(File.extname(file_path).downcase)
      end
    end
  end
end
