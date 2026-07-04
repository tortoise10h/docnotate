class CreateDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :documents do |t|
      t.string :file_path, null: false
      t.text :content, null: false

      t.timestamps
    end
    add_index :documents, :file_path, unique: true
  end
end
