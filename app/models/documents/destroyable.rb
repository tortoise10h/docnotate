module Documents
  module Destroyable
    extend ActiveSupport::Concern

    included do
      before_destroy :purge_associated_records
    end

    private

    # Bulk-delete dependent records in FK-safe order instead of cascading
    # ActiveRecord dependent: :destroy callbacks across thousands of
    # DocumentNode rows (which triggers recursive per-node queries and hangs).
    def purge_associated_records
      self.class.where(id: id).update_all(current_version_id: nil)

      version_rows = document_versions.pluck(:id, :content_type, :content_id)
      version_ids = version_rows.map(&:first)
      html_content_ids = version_rows.filter_map do |_, content_type, content_id|
        content_id if content_type == "HtmlContent" && content_id.present?
      end

      Comment.where(document_id: id).delete_all
      if version_ids.any?
        DocumentNode.where(document_version_id: version_ids).delete_all
        DocumentVersion.where(id: version_ids).delete_all
      end
      HtmlContent.where(id: html_content_ids).delete_all if html_content_ids.any?
    end
  end
end
