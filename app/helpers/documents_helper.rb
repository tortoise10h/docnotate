# frozen_string_literal: true

module DocumentsHelper
  def render_document_nodes(nodes)
    return "".html_safe if nodes.blank?

    buf = +""
    nodes.each { |node| append_document_node(node, buf) }
    buf.html_safe
  end

  def render_document_node(node)
    return "".html_safe if node.nil?

    buf = +""
    append_document_node(node, buf)
    buf.html_safe
  end

  private

  def append_document_node(node, buf)
    case node.node_type
    when "document"
      append_document_node_children(node, buf)
    when "paragraph"
      buf << %(<p id="#{ERB::Util.h(node.node_id)}" class="document-node document-node--paragraph">)
      append_document_node_children(node, buf)
      buf << "</p>"
    when "heading"
      level = ERB::Util.h(node.heading_level)
      buf << %(<h#{level} id="#{ERB::Util.h(node.node_id)}" class="document-node document-node--heading document-node--heading-#{level}">)
      append_document_node_children(node, buf)
      buf << "</h#{level}>"
    when "text"
      buf << ERB::Util.h(node.content)
    when "strong"
      buf << '<strong class="document-node document-node--strong">'
      append_document_node_children(node, buf)
      buf << "</strong>"
    when "emph"
      buf << '<em class="document-node document-node--emph">'
      append_document_node_children(node, buf)
      buf << "</em>"
    when "code"
      buf << %(<code class="document-node document-node--code">#{ERB::Util.h(node.content)}</code>)
    when "code_block"
      lang = node.meta&.dig("language").presence
      lang_attr = lang ? %( class="language-#{ERB::Util.h(lang)}") : ""
      buf << %(<pre id="#{ERB::Util.h(node.node_id)}" class="document-node document-node--code-block"><code#{lang_attr}>#{ERB::Util.h(node.content)}</code></pre>)
    when "list"
      list_tag = node.meta&.dig("list_type") == "ordered" ? "ol" : "ul"
      buf << %(<#{list_tag} id="#{ERB::Util.h(node.node_id)}" class="document-node document-node--list">)
      append_document_node_children(node, buf)
      buf << "</#{list_tag}>"
    when "item"
      buf << '<li class="document-node document-node--item">'
      append_document_node_children(node, buf)
      buf << "</li>"
    when "link"
      url = ERB::Util.h(node.meta&.dig("url"))
      title = ERB::Util.h(node.meta&.dig("title"))
      buf << %(<a href="#{url}" title="#{title}" class="document-node document-node--link">)
      append_document_node_children(node, buf)
      buf << "</a>"
    when "image"
      url = ERB::Util.h(node.meta&.dig("url"))
      alt = ERB::Util.h(node.content)
      title = ERB::Util.h(node.meta&.dig("title"))
      buf << %(<img src="#{url}" alt="#{alt}" title="#{title}" id="#{ERB::Util.h(node.node_id)}" class="document-node document-node--image">)
    when "blockquote"
      buf << %(<blockquote id="#{ERB::Util.h(node.node_id)}" class="document-node document-node--blockquote">)
      append_document_node_children(node, buf)
      buf << "</blockquote>"
    when "thematic_break"
      buf << %(<hr id="#{ERB::Util.h(node.node_id)}" class="document-node document-node--thematic-break">)
    when "table"
      children = node.children.to_a
      header_row = children.first
      body_rows = children.drop(1)
      buf << %(<table id="#{ERB::Util.h(node.node_id)}" class="document-node document-node--table"><thead>)
      append_document_node(header_row, buf) if header_row
      buf << "</thead><tbody>"
      body_rows.each { |row| append_document_node(row, buf) }
      buf << "</tbody></table>"
    when "table_row"
      buf << %(<tr id="#{ERB::Util.h(node.node_id)}" class="document-node document-node--table-row">)
      append_document_node_children(node, buf)
      buf << "</tr>"
    when "table_cell"
      cell_tag = node.meta&.dig("is_header") ? "th" : "td"
      th_class = cell_tag == "th" ? " document-node--table-cell-th" : ""
      buf << %(<#{cell_tag} id="#{ERB::Util.h(node.node_id)}" class="document-node document-node--table-cell#{th_class}">)
      append_document_node_children(node, buf)
      buf << "</#{cell_tag}>"
    when "softbreak"
      buf << '<br class="document-node document-node--softbreak">'
    when "linebreak"
      buf << '<br class="document-node document-node--linebreak">'
    else
      append_document_node_children(node, buf)
    end
  end

  def append_document_node_children(node, buf)
    node.children.each { |child| append_document_node(child, buf) }
  end
end
