class AddVersionAndResolvedToComments < ActiveRecord::Migration[8.1]
  def change
    add_reference :comments, :document_version, null: false, foreign_key: true
    add_column :comments, :is_resolved, :boolean, default: false, null: false
  end
end
