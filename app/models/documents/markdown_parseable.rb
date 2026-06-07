module Documents
  module MarkdownParseable
    extend ActiveSupport::Concern

    BLOCK_LEVEL_TYPES = %i[
      paragraph heading code_block list item
      block_quote thematic_break
    ].freeze

    private

    def parse_md_ast
      ast = CommonMarker.parse(content)
    end

    def build_nodes(ast)
    end
  end
end
