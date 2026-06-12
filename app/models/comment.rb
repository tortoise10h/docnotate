class Comment < ApplicationRecord
  belongs_to :document

  validates :document, presence: true
  validates :content, presence: true
end
