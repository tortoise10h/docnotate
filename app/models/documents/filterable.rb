module Documents
  module Filterable
    extend ActiveSupport::Concern

    SEPARATORS = [ "-", "_", ".", "/", "\\" ].freeze
    SEPARATOR_PATTERN = /[\s\-_.\/\\]+/

    included do
      scope :matching_title, ->(query) {
        if query.blank?
          all
        else
          tokens = Filterable.tokenize_title_query(query)
          # A query made solely of separators (e.g. "_") has no tokens; return none so "_" never acts as a LIKE wildcard.
          if tokens.empty?
            none
          else
            where(*Filterable.title_match_conditions(self, tokens))
          end
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
          tokens = Filterable.tokenize_title_query(query)
          if tokens.empty?
            none
          else
            matching_title(query)
              .select(:id, :name, :file_path, :file_type, :last_opened_at)
              .order(Arel.sql(Filterable.title_rank_order_sql(self, tokens)), last_opened_at: :desc, id: :desc)
              .limit(limit)
          end
        end
      }
    end

    class << self
      def tokenize_title_query(query)
        query.to_s.strip.split(SEPARATOR_PATTERN).reject(&:empty?)
      end

      def title_match_conditions(model, tokens)
        norm_name = normalized_sql_expr("documents.name")
        norm_path = normalized_sql_expr("documents.file_path")

        clauses = []
        binds = {}

        tokens.uniq.each_with_index do |token, index|
          key = :"token_#{index}"
          clauses << "(#{norm_name} LIKE :#{key} ESCAPE '\\' OR #{norm_path} LIKE :#{key} ESCAPE '\\')"
          binds[key] = "%#{model.sanitize_sql_like(token)}%"
        end

        [ clauses.join(" AND "), binds ]
      end

      def title_rank_order_sql(model, tokens)
        norm_display = normalized_sql_expr(display_name_sql_expr)
        binds = { prefix: "#{model.sanitize_sql_like(tokens.join(' '))}%" }

        display_token_clauses = tokens.uniq.each_with_index.map do |token, index|
          key = :"rank_token_#{index}"
          binds[key] = "%#{model.sanitize_sql_like(token)}%"
          "#{norm_display} LIKE :#{key} ESCAPE '\\'"
        end

        sql = <<~SQL.squish
          CASE
            WHEN #{norm_display} LIKE :prefix ESCAPE '\\' THEN 0
            WHEN #{display_token_clauses.join(' AND ')} THEN 1
            ELSE 2
          END ASC
        SQL

        model.sanitize_sql_array([ sql, binds ])
      end

      private

      def normalized_sql_expr(column_sql)
        SEPARATORS.reduce("COALESCE(#{column_sql}, '')") do |expr, separator|
          quoted = separator == "\\" ? "'\\'" : "'#{separator}'"
          "REPLACE(#{expr}, #{quoted}, ' ')"
        end
      end

      def display_name_sql_expr
        basename_sql = <<~SQL.squish
          (
            WITH RECURSIVE path_parts(rest) AS (
              SELECT REPLACE(documents.file_path, '\\', '/')
              UNION ALL
              SELECT SUBSTR(rest, INSTR(rest, '/') + 1)
              FROM path_parts
              WHERE INSTR(rest, '/') > 0
            )
            SELECT rest FROM path_parts WHERE INSTR(rest, '/') = 0 LIMIT 1
          )
        SQL

        "COALESCE(NULLIF(TRIM(documents.name), ''), #{basename_sql})"
      end
    end
  end
end
