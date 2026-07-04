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

        nodes = MarkdownParser.new(document_version_id: new_version.id, content: content).parse
        DocumentNode.insert_all!(nodes)

        update_column(:current_version_id, new_version.id)
      end

      association(:current_version).reset
    end

    def root_node_tree
      return [] unless current_version

      DocumentNode.tree_for(current_version.id)
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
