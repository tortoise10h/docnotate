class AddCurrentVersionToDocuments < ActiveRecord::Migration[8.1]
  def change
    add_reference :documents, :current_version, foreign_key: { to_table: :document_versions }
  end
end
