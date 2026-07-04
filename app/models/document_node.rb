class DocumentNode < ApplicationRecord
  belongs_to :document_version
  belongs_to :parent, class_name: "DocumentNode", optional: true
  has_many :children, -> { ordered }, class_name: "DocumentNode", foreign_key: "parent_id", dependent: :destroy

  scope :ordered, -> { order(:position) }

  attr_accessor :children_array

  def self.tree_for(document_version_id)
    nodes = where(document_version_id: document_version_id).ordered.to_a
    build_tree(nodes)
  end

  def self.build_tree(nodes)
    node_map = {}
    roots = []

    nodes.each do |node|
      node.children_array = []
      node_map[node.id] = node
    end

    nodes.each do |node|
      if node.parent_id && node_map[node.parent_id]
        node_map[node.parent_id].children_array << node
      else
        roots << node
      end
    end

    nodes.each do |node|
      node.association(:children).target = node.children_array
    end

    roots
  end
end
