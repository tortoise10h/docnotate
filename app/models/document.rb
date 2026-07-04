class Document < ApplicationRecord
  include Documents::FileTypeable, Documents::AstParseable,
          Documents::FileSyncable, Documents::Highlightable

  validates :file_path, presence: true
  validates :file_type, presence: true
  validates :content, presence: true

  belongs_to :current_version, class_name: "DocumentVersion", optional: true
  has_many :document_versions, dependent: :destroy
  has_many :document_nodes, through: :current_version
  has_many :comments, dependent: :destroy

  def touch_last_opened!
    update_column(:last_opened_at, Time.current)
  end
end
