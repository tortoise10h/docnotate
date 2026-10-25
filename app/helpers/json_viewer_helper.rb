module JsonViewerHelper
  def render_json_tokens(node)
    case node.node_type
    when "json_open"
      parts = []
      if (key = node.meta&.dig("key"))
        parts << content_tag(:span, "\"#{key}\"", class: "hljs-attr")
        parts << content_tag(:span, ":", class: "json-line__punct")
        parts << " "
      end
      parts << content_tag(:span, node.meta&.dig("bracket"), class: "json-line__punct")
      safe_join(parts)
    when "json_close"
      bracket = node.meta&.dig("bracket")
      comma = node.meta&.dig("trailing_comma") ? "," : ""
      content_tag(:span, "#{bracket}#{comma}", class: "json-line__punct")
    when "json_primitive"
      parts = []
      if (key = node.meta&.dig("key"))
        parts << content_tag(:span, "\"#{key}\"", class: "hljs-attr")
        parts << content_tag(:span, ":", class: "json-line__punct")
        parts << " "
      end
      value_type = node.meta&.dig("value_type")
      value_json = node.meta&.dig("value_json").to_s
      case value_type
      when "string"
        parts << content_tag(:span, value_json, class: "hljs-string")
      when "number"
        parts << content_tag(:span, value_json, class: "hljs-number")
      when "boolean", "null"
        parts << content_tag(:span, value_json, class: "hljs-literal")
      when "object", "array"
        parts << content_tag(:span, value_json, class: "json-line__punct")
      else
        parts << value_json
      end
      parts << content_tag(:span, ",", class: "json-line__punct") if node.meta&.dig("trailing_comma")
      safe_join(parts)
    else
      node.content.to_s
    end
  end
end
