# frozen_string_literal: true

module Markdown
  class CalloutParser
    CALLOUT_REGEX = /\A\s*\[!(?<type>[a-zA-Z0-9_-]+)\](?:[ \t]*(?<collapse>[+-]))?(?:[ \t]+(?<title>[^\r\n]*))?\s*\z/

    CALLOUT_TYPES = {
      # note theme
      "note" => { theme: "note", title: "Note" },
      "seealso" => { theme: "note", title: "See Also" },
      "info" => { theme: "note", title: "Info" },
      "todo" => { theme: "note", title: "Todo" },
      "abstract" => { theme: "note", title: "Abstract" },
      "summary" => { theme: "note", title: "Summary" },
      "tldr" => { theme: "note", title: "TL;DR" },
      "quote" => { theme: "note", title: "Quote" },
      "cite" => { theme: "note", title: "Cite" },

      # tip theme
      "tip" => { theme: "tip", title: "Tip" },
      "hint" => { theme: "tip", title: "Hint" },
      "success" => { theme: "tip", title: "Success" },
      "check" => { theme: "tip", title: "Check" },
      "done" => { theme: "tip", title: "Done" },

      # important theme
      "important" => { theme: "important", title: "Important" },
      "question" => { theme: "important", title: "Question" },
      "help" => { theme: "important", title: "Help" },
      "faq" => { theme: "important", title: "FAQ" },
      "example" => { theme: "important", title: "Example" },

      # warning theme
      "warning" => { theme: "warning", title: "Warning" },
      "attention" => { theme: "warning", title: "Attention" },
      "warn" => { theme: "warning", title: "Warning" },

      # caution theme
      "caution" => { theme: "caution", title: "Caution" },
      "danger" => { theme: "caution", title: "Danger" },
      "error" => { theme: "caution", title: "Error" },
      "failure" => { theme: "caution", title: "Failure" },
      "fail" => { theme: "caution", title: "Fail" },
      "missing" => { theme: "caution", title: "Missing" },
      "bug" => { theme: "caution", title: "Bug" }
    }.freeze

    ICON_SVGS = {
      "note" => '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><path d="M12 16v-4"/><path d="M12 8h.01"/></svg>',
      "tip" => '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M15 14c.2-1 .7-1.7 1.5-2.5 1-.9 1.5-2.2 1.5-3.5A6 6 0 0 0 6 8c0 1 .2 2.2 1.5 3.5.7.7 1.3 1.5 1.5 2.5"/><path d="M9 18h6"/><path d="M10 22h4"/></svg>',
      "important" => '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" x2="12" y1="8" y2="12"/><line x1="12" x2="12.01" y1="16" y2="16"/></svg>',
      "warning" => '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3Z"/><line x1="12" x2="12" y1="9" y2="13"/><line x1="12" x2="12.01" y1="17" y2="17"/></svg>',
      "caution" => '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="7.86 2 16.14 2 22 7.86 22 16.14 16.14 22 7.86 22 2 16.14 2 7.86 7.86 2"/><line x1="12" x2="12" y1="8" y2="12"/><line x1="12" x2="12.01" y1="16" y2="16"/></svg>'
    }.freeze

    FOLD_ICON_SVG = '<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m6 9 6 6 6-6"/></svg>'

    class << self
      def parse_callout(node)
        return nil unless node.type == :block_quote

        para = node.first_child
        return nil unless para&.type == :paragraph

        text_node = para.first_child
        return nil unless text_node&.type == :text

        raw_text = text_node.string_content.to_s
        first_line = raw_text.lines.first.to_s.chomp
        match = first_line.match(CALLOUT_REGEX)
        return nil unless match

        type_info = CALLOUT_TYPES[match[:type].downcase]
        return nil unless type_info

        theme = type_info[:theme]
        title_text = match[:title].to_s.strip
        custom_title = title_text.present?
        title = custom_title ? title_text : type_info[:title]

        collapsible = case match[:collapse]
        when "-" then "collapsed"
        when "+" then "expanded"
        end

        # Normalize Commonmarker AST: delete marker line and trailing break
        if raw_text == first_line
          nxt = text_node.next_sibling
          nxt.delete if nxt && %i[softbreak linebreak].include?(nxt.type)
          text_node.delete
        else
          # Text node contained more text after newline (defensive fallback)
          text_node.string_content = raw_text[first_line.length..].sub(/\A\r?\n/, "")
        end

        # Drop the paragraph if it became completely empty
        para.delete if para.first_child.nil?

        {
          "type" => theme,
          "title" => title,
          "custom_title" => custom_title,
          "collapsible" => collapsible
        }
      end

      def icon_svg(theme)
        ICON_SVGS[theme] || ICON_SVGS["note"]
      end

      def render_callouts_in_html(html)
        return html if html.blank? || !html.include?("<blockquote")

        fragment = Nokogiri::HTML::DocumentFragment.parse(html)
        fragment.css("blockquote").each do |bq|
          para = bq.at_xpath("./p[1]")
          next unless para

          first_child = para.children.first
          next unless first_child&.text?

          raw_text = first_child.text
          first_line = raw_text.lines.first.to_s.chomp
          match = first_line.match(CALLOUT_REGEX)
          next unless match

          type_info = CALLOUT_TYPES[match[:type].downcase]
          next unless type_info

          theme = type_info[:theme]
          title_text = match[:title].to_s.strip
          title = title_text.present? ? title_text : type_info[:title]

          collapsible = case match[:collapse]
          when "-" then "collapsed"
          when "+" then "expanded"
          end

          # Remove the marker text
          if raw_text == first_line
            first_child.remove
          else
            first_child.content = raw_text[first_line.length..].sub(/\A\r?\n/, "")
          end

          # Remove adjacent <br> if present
          next_elem = para.children.first
          next_elem.remove if next_elem&.name == "br"

          # Drop paragraph if now empty
          para.remove if para.text.strip.empty? && para.element_children.empty?

          tag = collapsible ? "details" : "div"
          header_tag = collapsible ? "summary" : "div"
          open_attr = (collapsible == "expanded") ? " open" : ""
          collapsible_cls = collapsible ? " callout--collapsible" : ""

          callout_html = +%(<#{tag} class="callout callout--#{theme}#{collapsible_cls}"#{open_attr}>)
          callout_html << %(<#{header_tag} class="callout__header">)
          callout_html << %(<span class="callout__icon" aria-hidden="true">#{icon_svg(theme)}</span>)
          callout_html << %(<span class="callout__title">#{ERB::Util.h(title)}</span>)
          if collapsible
            callout_html << %(<span class="callout__fold-icon" aria-hidden="true">#{FOLD_ICON_SVG}</span>)
          end
          callout_html << %(</#{header_tag}>)
          callout_html << %(<div class="callout__content">#{bq.inner_html}</div>)
          callout_html << %(</#{tag}>)

          bq.replace(callout_html)
        end

        fragment.to_html
      end
    end
  end
end
