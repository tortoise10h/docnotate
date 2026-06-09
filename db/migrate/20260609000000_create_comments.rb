class CreateComments < ActiveRecord::Migration[8.1]
  def change
    create_table :comments do |t|
      t.string :start_block_id
      t.string :end_block_id
      t.integer :start_offset
      t.integer :end_offset
      t.text :selected_text
      t.text :prefix_text
      t.text :postfix_text
      t.references :document, null: false, foreign_key: true

      t.timestamps
    end
  end
end
