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
      def file_type_from_path(file_path)
        ext = File.extname(file_path).downcase
        case ext
        when ".md", ".markdown", ".mdx"
          "markdown"
        when ".txt"
          "text"
        else
          "markdown"
        end
      end
    end
  end
end
