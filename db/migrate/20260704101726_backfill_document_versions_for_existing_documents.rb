class BackfillDocumentVersionsForExistingDocuments < ActiveRecord::Migration[8.1]
  def up
    Document.find_each do |document|
      version = DocumentVersion.create!(
        document_id: document.id,
        version: document.version,
        size: document.size,
        last_modified_at: document.last_modified_at
      )
      DocumentNode.where(document_version_id: document.id).update_all(document_version_id: version.id)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
