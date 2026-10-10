class CreateHtmlContents < ActiveRecord::Migration[8.1]
  def change
    create_table :html_contents do |t|
      t.text :annotated_html, null: false
      t.timestamps
    end

    add_reference :document_versions, :content, polymorphic: true
  end
end
