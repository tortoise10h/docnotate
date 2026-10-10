module Documents
  module AstParseable
    extend ActiveSupport::Concern

    ParseMetadata = Data.define(:size, :last_modified_at)

    def parse_ast_and_save!(metadata:)
      metadata = ParseMetadata.new(**metadata) if metadata.is_a?(Hash)

      transaction do
        previous_version = current_version
        new_version = document_versions.create!(
          version: next_version,
          size: metadata.size,
          last_modified_at: metadata.last_modified_at
        )

        previous_version&.document_nodes&.delete_all

        parser = document_parser_for(new_version.id)
        DocumentNode.insert_all!(parser.parse)
        new_version.update!(content: HtmlContent.create!(annotated_html: parser.annotated_html)) if html?

        update_column(:current_version_id, new_version.id)
      end

      association(:current_version).reset
    end

    def root_node_tree
      return [] unless current_version

      DocumentNode.tree_for(current_version.id)
    end

    def document_parser_for(document_version_id)
      parser_class = html? ? HtmlParser : MarkdownParser
      parser_class.new(document_version_id:, content:)
    end

    def next_version
      return "v1" if current_version&.version.blank?

      match = current_version.version.match(/v(\d+)/)
      if match
        "v#{match[1].to_i + 1}"
      else
        "v1"
      end
    end
  end
end
