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
        if file_type.in?(%w[markdown html org])
          where(file_type: file_type)
        else
          all
        end
      }

      scope :search_by_title, ->(query, limit: 20) {
        if query.blank?
          none
        else
          matching_title(query)
            .select(:id, :name, :file_path, :file_type, :last_opened_at)
            .order(last_opened_at: :desc, id: :desc)
            .limit(limit)
        end
      }
    end
  end
end
