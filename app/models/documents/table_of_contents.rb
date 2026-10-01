module Documents
  module TableOfContents
    extend ActiveSupport::Concern

    TocEntry = Data.define(:id, :level, :text)

    def table_of_contents(root_nodes = root_node_tree)
      collect_headings(root_nodes)
    end

    private

    def collect_headings(nodes)
      nodes.flat_map do |node|
        entries = if node.node_type == "heading" && (1..3).cover?(node.heading_level)
          [ TocEntry.new(id: node.node_id, level: node.heading_level, text: heading_text(node)) ]
        else
          []
        end

        entries + collect_headings(node.children)
      end
    end

    def heading_text(node)
      return node.content.to_s if node.children.empty?

      node.children.map { |child| heading_text(child) }.join
    end
  end
end
