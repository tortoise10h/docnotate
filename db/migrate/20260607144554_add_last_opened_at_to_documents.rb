class AddLastOpenedAtToDocuments < ActiveRecord::Migration[8.1]
  def change
    add_column :documents, :last_opened_at, :datetime
  end
end
