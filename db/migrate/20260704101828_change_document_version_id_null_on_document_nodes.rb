class ChangeDocumentVersionIdNullOnDocumentNodes < ActiveRecord::Migration[8.1]
  def change
    change_column_null :document_nodes, :document_version_id, false
  end
end
