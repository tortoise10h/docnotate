module Comments
  module Renderable
    extend ActiveSupport::Concern

    # Agent comments arrive as markdown, so render once server-side and share
    # one output across every comment surface (popover, archived list). The
    # default render.unsafe = false omits raw HTML from the source, which is
    # why no extra sanitizer is needed for agent-supplied content.
    def rendered_content
      html = Commonmarker.to_html(content, options: { render: { unsafe: false } }, plugins: { syntax_highlighter: nil })
      Markdown::CalloutParser.render_callouts_in_html(html).html_safe
    end
  end
end
