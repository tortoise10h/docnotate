module Documents
  module Filterable
    extend ActiveSupport::Concern

    included do
      scope :matching_title, ->(query) {
        if query.blank?
          all
        else
          pattern = "%#{sanitize_sql_like(query.strip)}%"
          where("documents.name LIKE :pattern ESCAPE '\\' OR documents.file_path LIKE :pattern ESCAPE '\\'", pattern: pattern)
        end
      }

      scope :with_file_type, ->(file_type) {
        if file_type.in?(%w[markdown html])
          where(file_type: file_type)
        else
          all
        end
      }
    end
  end
end
