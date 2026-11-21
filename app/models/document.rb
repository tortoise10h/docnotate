class Document < ApplicationRecord
  include Documents::FileTypeable, Documents::AstParseable,
          Documents::FileSyncable, Documents::Commentable,
          Documents::ContentOutline,
          Documents::TableOfContents, Documents::Assets,
          Documents::Filterable, Documents::Destroyable

  validates :file_path, presence: true
  validates :file_type, presence: true
  validates :content, presence: true

  belongs_to :current_version, class_name: "DocumentVersion", optional: true
  has_many :document_versions
  has_many :document_nodes, through: :current_version
  has_many :comments

  scope :recently_opened, -> { where.not(last_opened_at: nil).order(last_opened_at: :desc) }

  def display_name = name.presence || File.basename(file_path)

  def touch_last_opened!
    update_column(:last_opened_at, Time.current)
  end
end
