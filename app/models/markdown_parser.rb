class MarkdownParser
  BLOCK_LEVEL_TYPES = %i[
    paragraph heading code_block list item
    block_quote thematic_break
  ].freeze

  def initialize(document_version_id:, content:)
    @document_version_id = document_version_id
    @content = content
  end

  def parse
    ast = Commonmarker.parse(@content)
    nodes = []

    build_nodes(node: ast, parent_id: nil, position: 0, nodes:)

    nodes
  end

  private

  def build_nodes(node:, parent_id:, position:, nodes:)
    db_id = SecureRandom.uuid_v7
    attrs = node_attributes(node:, parent_id:, position:)
    attrs[:id] = db_id

    nodes << attrs

    child = node.first_child
    child_position = 0
    while child
      build_nodes(node: child, parent_id: db_id, position: child_position, nodes: nodes)
      child = child.next_sibling
      child_position += 1
    end
  end

  def node_attributes(node:, parent_id:, position:)
    {
      document_version_id: @document_version_id,
      parent_id:,
      position:,
      node_type: node.type.to_s,
      content: node_content(node),
      heading_level: node_heading_level(node),
      meta: node_metadata(node),
      node_id: block_level?(node) ? unique_block_id : nil,
      created_at: Time.current,
      updated_at: Time.current
    }
  end

  def node_content(node)
    return nil if node.first_child

    begin
      node.string_content
    rescue TypeError
      nil
    end
  end

  def node_heading_level(node)
    return nil unless node.type == :heading

    node.header_level
  end

  def node_metadata(node)
    case node.type
    when :code_block
      { "language" => node.fence_info.to_s }
    when :link
      { "url" => node.url.to_s, "title" => node.title.to_s }
    when :list
      {
        "list_type" => node.list_type.to_s,
        "tight" => node.list_tight
      }
    when :image
      {
        "url" => node.url.to_s,
        "title" => node.title.to_s
      }
    else
      nil
    end
  end

  def unique_block_id
    "block-#{SecureRandom.hex(4)}"
  end

  def block_level?(node)
    BLOCK_LEVEL_TYPES.include?(node.type)
  end
end
