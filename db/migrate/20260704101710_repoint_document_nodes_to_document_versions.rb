class RepointDocumentNodesToDocumentVersions < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :document_nodes, :documents
    rename_column :document_nodes, :document_id, :document_version_id
    change_column :document_nodes, :document_version_id, :integer
    change_column_null :document_nodes, :document_version_id, false
    add_foreign_key :document_nodes, :document_versions
  end
end
