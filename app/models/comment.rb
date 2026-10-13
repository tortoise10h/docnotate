class Comment < ApplicationRecord
  include Comments::Renderable

  belongs_to :document
  belongs_to :document_version

  validates :document, presence: true
  validates :document_version, presence: true
  validates :content, presence: true

  validate :document_version_matches_document

  before_validation :ensure_version_and_document_consistency, on: :create

  private

  def ensure_version_and_document_consistency
    if document && document_version.nil?
      self.document_version_id ||= document.current_version&.id
    elsif document_version && document.nil?
      self.document_id ||= document_version.document_id
    end
  end

  def document_version_matches_document
    return unless document_version && document

    errors.add(:document_version_id, "must belong to the same document") if document_version.document_id != document_id
  end
end
