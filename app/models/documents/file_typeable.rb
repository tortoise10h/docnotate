module Documents
  module FileTypeable
    extend ActiveSupport::Concern

    FILE_TYPES = %w[markdown html org text pdf].freeze

    FILE_TYPES.each do |type|
      define_method("#{type}?") { file_type == type }
    end

    def file_type_from_path
      self.class.file_type_from_path(file_path)
    end

    class_methods do
      MARKDOWN_EXTENSIONS = %w[.md .markdown .mdx].freeze
      HTML_EXTENSIONS = %w[.html .htm].freeze
      ORG_EXTENSIONS = %w[.org].freeze

      def file_type_from_path(file_path)
        file_path = normalize_file_path(file_path) if respond_to?(:normalize_file_path)
        ext = File.extname(file_path).downcase
        case ext
        when *MARKDOWN_EXTENSIONS
          "markdown"
        when *HTML_EXTENSIONS
          "html"
        when *ORG_EXTENSIONS
          "org"
        when ".txt"
          "text"
        else
          "markdown"
        end
      end

      def supported_file?(file_path)
        markdown_file?(file_path) || html_file?(file_path) || org_file?(file_path)
      end

      def markdown_file?(file_path)
        file_path = normalize_file_path(file_path) if respond_to?(:normalize_file_path)
        MARKDOWN_EXTENSIONS.include?(File.extname(file_path).downcase)
      end

      def html_file?(file_path)
        file_path = normalize_file_path(file_path) if respond_to?(:normalize_file_path)
        HTML_EXTENSIONS.include?(File.extname(file_path).downcase)
      end

      def org_file?(file_path)
        file_path = normalize_file_path(file_path) if respond_to?(:normalize_file_path)
        ORG_EXTENSIONS.include?(File.extname(file_path).downcase)
      end
    end
  end
end
