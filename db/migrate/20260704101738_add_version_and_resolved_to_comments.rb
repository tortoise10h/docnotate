class AddVersionAndResolvedToComments < ActiveRecord::Migration[8.1]
  def up
    add_reference :comments, :document_version, foreign_key: true
    add_column :comments, :is_resolved, :boolean, default: false, null: false

    execute <<~SQL
      UPDATE comments
      SET document_version_id = (
        SELECT document_versions.id
        FROM document_versions
        WHERE document_versions.document_id = comments.document_id
      )
    SQL

    change_column_null :comments, :document_version_id, false
  end

  def down
    remove_column :comments, :is_resolved
    remove_reference :comments, :document_version
  end
end
