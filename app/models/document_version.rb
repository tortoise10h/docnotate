class DocumentVersion < ApplicationRecord
  belongs_to :document
  delegated_type :content, types: %w[HtmlContent], optional: true, dependent: :destroy
  has_many :document_nodes, dependent: :destroy
  has_many :comments, dependent: :destroy

  def resolve_all_comments!(resolved)
    comments.update_all(is_resolved: resolved)
  end
end
