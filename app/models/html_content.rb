class HtmlContent < ApplicationRecord
  has_one :document_version, as: :content
end
