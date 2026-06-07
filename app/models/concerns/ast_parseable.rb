module AstParseable
  extend ActiveSupport::Concern

  included do
    has_many :document_nodes, dependent: :destroy

    after_save :parse_ast, if: :saved_change_to_content?
  end

  BLOCK_LEVEL_TYPES = %i[
    paragraph heading code_block list item
    block_quote thematic_break
  ].freeze

  def root_node_tree
    DocumentNode.tree_for(id)
  end

  private

  def parse_ast
    document_nodes.destroy_all

    doc = Commonmarker.parse(content)
    nodes = []

    build_nodes(doc, parent_id: nil, position: 0, nodes: nodes)
    DocumentNode.insert_all!(nodes) unless nodes.empty?
  end

  def build_nodes(cm_node, parent_id:, position:, nodes:)
    node_id = SecureRandom.uuid
    attrs = node_attributes(cm_node)

    nodes << {
      id: node_id,
      document_id: id,
      parent_id: parent_id,
      position: position,
      node_type: cm_node.type.to_s,
      content: attrs[:content],
      heading_level: attrs[:heading_level],
      meta: attrs[:meta],
      node_id: attrs[:node_id],
      created_at: Time.current,
      updated_at: Time.current
    }

    child = cm_node.first_child
    child_position = 0
    while child
      build_nodes(child, parent_id: node_id, position: child_position, nodes: nodes)
      child = child.next_sibling
      child_position += 1
    end
  end

  def node_attributes(cm_node)
    {
      content: extract_content(cm_node),
      heading_level: extract_heading_level(cm_node),
      meta: extract_meta(cm_node),
      node_id: block_level?(cm_node) ? "block-#{SecureRandom.hex(4)}" : nil
    }
  end

  def block_level?(cm_node)
    BLOCK_LEVEL_TYPES.include?(cm_node.type)
  end

  def extract_content(cm_node)
    return nil if cm_node.first_child

    begin
      cm_node.string_content
    rescue TypeError
      nil
    end
  end

  def extract_heading_level(cm_node)
    return nil unless cm_node.type == :heading

    cm_node.header_level
  end

  def extract_meta(cm_node)
    case cm_node.type
    when :code_block
      { "language" => cm_node.fence_info.to_s }
    when :link
      { "url" => cm_node.url.to_s, "title" => cm_node.title.to_s }
    when :list
      {
        "list_type" => cm_node.list_type.to_s,
        "tight" => cm_node.list_tight
      }
    when :image
      {
        "url" => cm_node.url.to_s,
        "title" => cm_node.title.to_s
      }
    else
      nil
    end
  end
end
