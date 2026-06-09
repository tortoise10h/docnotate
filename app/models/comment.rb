class Comment < ApplicationRecord
  belongs_to :document

  validates :document, presence: true
end
