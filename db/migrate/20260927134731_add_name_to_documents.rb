class AddNameToDocuments < ActiveRecord::Migration[8.1]
  def change
    add_column :documents, :name, :string
  end
end
