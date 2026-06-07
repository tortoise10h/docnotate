class Document < ApplicationRecord
  include Documents::FileTypeable, Documents::AstParseable

  has_many :document_nodes, dependent: :destroy

  def parse_ast_and_save!
    document_nodes = parse_ast
    DocumentNode.insert_all!(document_nodes)
  end

  def root_node_tree
    DocumentNode.tree_for(id)
  end
end
