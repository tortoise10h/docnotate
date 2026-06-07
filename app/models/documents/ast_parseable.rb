module Documents
  module AstParseable
    def parse_ast
      parser.parse
    end

    def parser
      MarkdownParser.new(document: self)
    end
  end
end
