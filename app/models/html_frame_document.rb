# Serves a stored annotated version inside the viewer iframe. The shared anchor helpers and the
# in-frame client are inlined here rather than stored, so client fixes apply without reparsing.
class HtmlFrameDocument
  SCRIPT_SOURCES = [
    Rails.root.join("app/javascript/utils/text_anchors.js"),
    Rails.root.join("app/javascript/html_frame/client.js")
  ].freeze

  def initialize(annotated_html)
    @annotated_html = annotated_html
  end

  def to_html
    script = %(<script type="module">\n#{script_source}\n</script>)

    if @annotated_html.match?(%r{</body>}i)
      @annotated_html.sub(%r{</body>}i) { "#{script}</body>" }
    else
      @annotated_html + script
    end
  end

  private

  def script_source
    SCRIPT_SOURCES.map { |path| File.read(path) }.join("\n")
  end
end
