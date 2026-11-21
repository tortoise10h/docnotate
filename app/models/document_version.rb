class DocumentVersion < ApplicationRecord
  belongs_to :document
  delegated_type :content, types: %w[HtmlContent], optional: true, dependent: :destroy
  has_many :document_nodes, dependent: :delete_all
  has_many :comments, dependent: :delete_all

  def resolve_all_comments!(resolved)
    comments.update_all(is_resolved: resolved)
  end
end
