class CreateDocumentVersions < ActiveRecord::Migration[8.1]
  def change
    create_table :document_versions do |t|
      t.references :document, null: false, foreign_key: true
      t.string :version, null: false
      t.integer :size
      t.datetime :last_modified_at

      t.timestamps
    end

    add_index :document_versions, [:document_id, :version], unique: true
  end
end
