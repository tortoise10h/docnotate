module Comments
  module Renderable
    extend ActiveSupport::Concern

    # Agent comments arrive as markdown, so render once server-side and share
    # one output across every comment surface (popover, archived list). The
    # default render.unsafe = false omits raw HTML from the source, which is
    # why no extra sanitizer is needed for agent-supplied content.
    def rendered_content
      Commonmarker.to_html(content, plugins: { syntax_highlighter: nil }).html_safe
    end
  end
end
