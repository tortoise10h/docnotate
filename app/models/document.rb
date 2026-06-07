class Document < ApplicationRecord
  include Documents::FileTypeable, Documents::AstParseable, Documents::FileSyncable

  validates :file_path, presence: true
  validates :file_type, presence: true
  validates :content, presence: true

  has_many :document_nodes, dependent: :destroy

  def next_version
    return "v1" if version.blank?

    match = version.match(/v(\d+)/)
    if match
      number = match[1].to_i
      "v#{number + 1}"
    else
      "v1"
    end
  end

  def parse_ast_and_save!
    document_nodes = parse_ast
    DocumentNode.insert_all!(document_nodes)
  end

  def root_node_tree
    DocumentNode.tree_for(id)
  end
end
