require "test_helper"

class HtmlParserTest < ActiveSupport::TestCase
  test "tags block elements with data attributes and keeps the author's ids" do
    html = %(<html><body><h1 id="top">Title</h1><p>Hello <span>world</span></p><div id="chart"></div></body></html>)

    parser = HtmlParser.new(document_version_id: 1, content: html)
    nodes = parser.parse
    doc = Nokogiri::HTML5(parser.annotated_html)

    assert_equal nodes.map { |node| node[:node_id] }.sort, doc.css("[data-docnotate-block]").map { |el| el["data-docnotate-block"] }.sort
    assert nodes.all? { |node| node[:node_id].match?(/\Ablock-\h{8}\z/) }
    assert_equal "top", doc.at("h1")["id"]
    assert_equal "chart", doc.at("div")["id"]
  end

  test "builds heading nodes and keeps inline wrappers inside their paragraph" do
    html = %(<body><h2>Usage <em>now</em></h2><p>See <a href="#x">link</a> here</p></body>)

    nodes = HtmlParser.new(document_version_id: 1, content: html).parse

    heading = nodes.find { |node| node[:node_type] == "heading" }
    assert_equal 2, heading[:heading_level]
    assert_equal "Usage now", heading[:content]
    assert_equal [ "heading", "p" ], nodes.map { |node| node[:node_type] }
  end

  test "skips script content and nests blocks under their block ancestor" do
    html = %(<body><script>var s = "<p>not a block</p>";</script><ul><li><div>Nested text</div></li></ul></body>)

    nodes = HtmlParser.new(document_version_id: 1, content: html).parse

    assert_equal %w[ul li div], nodes.map { |node| node[:node_type] }
    _ul, li, div = nodes
    assert_equal li[:id], div[:parent_id]
    assert_equal "Nested text", div[:content]
    assert_nil li[:content]
  end

  test "parsing the same source again gives the same structure and only its own ids" do
    html = %(<body><h1>Title</h1><p>Body <em>text</em></p></body>)

    first = HtmlParser.new(document_version_id: 1, content: html)
    second = HtmlParser.new(document_version_id: 1, content: html)
    shape = ->(nodes) { nodes.map { |node| node.values_at(:node_type, :heading_level, :content, :position) } }

    assert_equal shape.call(first.parse), shape.call(second.parse)
    first_ids = Nokogiri::HTML5(first.annotated_html).css("[data-docnotate-block]").map { |el| el["data-docnotate-block"] }
    second_ids = Nokogiri::HTML5(second.annotated_html).css("[data-docnotate-block]").map { |el| el["data-docnotate-block"] }
    assert_equal 2, first_ids.size
    assert_empty first_ids & second_ids
  end
end
