class AddFileTypeToDocuments < ActiveRecord::Migration[8.1]
  def change
    add_column :documents, :file_type, :string, null: false, default: "markdown"
  end
end
