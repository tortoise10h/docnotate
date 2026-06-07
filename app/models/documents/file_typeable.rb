module Documents
  module FileTypeable
    extend ActiveSupport::Concern

    FILE_TYPES = %w[markdown text pdf].freeze

    FILE_TYPES.each do |type|
      define_method("#{type}?") { file_type == type }
    end

    def file_type_from_path
      ext = File.extname(file_path)
      case ext
      when ".md"
        "markdown"
      end
    end
  end
end
