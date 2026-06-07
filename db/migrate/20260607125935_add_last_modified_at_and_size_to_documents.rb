class AddLastModifiedAtAndSizeToDocuments < ActiveRecord::Migration[8.1]
  def change
    add_column :documents, :last_modified_at, :datetime
    add_column :documents, :size, :integer
  end
end
