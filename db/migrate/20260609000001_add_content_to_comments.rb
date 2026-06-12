class AddContentToComments < ActiveRecord::Migration[8.1]
  def change
    add_column :comments, :content, :text
  end
end
