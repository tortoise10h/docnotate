module Documents
  module AstParseable
    extend ActiveSupport::Concern

    def parse_ast_and_save!
      transaction do
        previous_version = document_versions.order(created_at: :desc).first
        new_version = document_versions.create!(
          version: next_version,
          size: size,
          last_modified_at: last_modified_at
        )

        previous_version&.document_nodes&.delete_all

        nodes = MarkdownParser.new(document_version_id: new_version.id, content: content).parse
        DocumentNode.insert_all!(nodes)

        update_column(:version, new_version.version)
      end

      association(:current_version).reset
    end

    def root_node_tree
      DocumentNode.tree_for(current_version.id)
    end

    def next_version
      latest_version = document_versions.order(created_at: :desc).first
      return "v1" if latest_version.blank? || latest_version.version.blank?

      match = latest_version.version.match(/v(\d+)/)
      if match
        "v#{match[1].to_i + 1}"
      else
        "v1"
      end
    end
  end
end
