class CreateDocumentNodes < ActiveRecord::Migration[8.1]
  def change
    create_table :document_nodes, id: false do |t|
      t.string :id, null: false, primary_key: true
      t.references :document, null: false, foreign_key: true
      t.string :node_type, null: false
      t.text :content
      t.string :node_id
      t.string :parent_id
      t.integer :position, null: false
      t.integer :heading_level
      t.json :meta

      t.timestamps
    end

    add_index :document_nodes, :parent_id
    add_foreign_key :document_nodes, :document_nodes, column: :parent_id
  end
end
