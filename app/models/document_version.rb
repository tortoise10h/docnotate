class DocumentVersion < ApplicationRecord
  belongs_to :document
  has_many :document_nodes, dependent: :destroy
  has_many :comments, dependent: :destroy
end
