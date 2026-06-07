class CreateDocumentNodes < ActiveRecord::Migration[8.1]
  def change
    create_table :document_nodes do |t|
      t.references :document, null: false, foreign_key: true
      t.string :node_type, null: false
      t.text :content
      t.string :node_id
      t.references :parent, foreign_key: { to_table: :document_nodes }
      t.integer :position, null: false
      t.integer :heading_level
      t.json :meta

      t.timestamps
    end
  end
end
