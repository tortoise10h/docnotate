# frozen_string_literal: true

require "test_helper"

class DocumentsHelperTest < ActionView::TestCase
  NodeStub = Struct.new(:node_type, :node_id, :heading_level, :content, :meta, :children, keyword_init: true) do
    def initialize(**kwargs)
      super
      self.children ||= []
    end
  end

  test "returns empty safe buffer for blank nodes" do
    assert_equal "", render_document_nodes(nil)
    assert render_document_nodes(nil).html_safe?
    assert_equal "", render_document_nodes([])
    assert render_document_nodes([]).html_safe?
    assert_equal "", render_document_node(nil)
    assert render_document_node(nil).html_safe?
  end

  test "renders paragraph and inline nodes" do
    tree = NodeStub.new(
      node_type: "paragraph",
      node_id: "block-p1",
      children: [
        NodeStub.new(node_type: "text", content: "Hello "),
        NodeStub.new(node_type: "strong", children: [ NodeStub.new(node_type: "text", content: "bold") ]),
        NodeStub.new(node_type: "text", content: " and "),
        NodeStub.new(node_type: "emph", children: [ NodeStub.new(node_type: "text", content: "italic") ]),
        NodeStub.new(node_type: "text", content: " and "),
        NodeStub.new(node_type: "code", content: "code()"),
        NodeStub.new(node_type: "softbreak"),
        NodeStub.new(node_type: "linebreak")
      ]
    )

    expected = '<p id="block-p1" class="document-node document-node--paragraph">' \
               'Hello ' \
               '<strong class="document-node document-node--strong">bold</strong>' \
               ' and ' \
               '<em class="document-node document-node--emph">italic</em>' \
               ' and ' \
               '<code class="document-node document-node--code">code()</code>' \
               '<br class="document-node document-node--softbreak">' \
               '<br class="document-node document-node--linebreak">' \
               "</p>"

    result = render_document_node(tree)
    assert_equal expected, result
    assert result.html_safe?
  end

  test "renders headings with appropriate level and classes" do
    node = NodeStub.new(
      node_type: "heading",
      heading_level: 2,
      node_id: "block-h2",
      children: [ NodeStub.new(node_type: "text", content: "Title") ]
    )

    expected = '<h2 id="block-h2" class="document-node document-node--heading document-node--heading-2">Title</h2>'
    assert_equal expected, render_document_node(node)
  end

  test "renders code blocks with and without language" do
    with_lang = NodeStub.new(
      node_type: "code_block",
      node_id: "block-code-1",
      content: "puts :hi",
      meta: { "language" => "ruby" }
    )
    expected_with_lang = '<pre id="block-code-1" class="document-node document-node--code-block"><code class="language-ruby">puts :hi</code></pre>'
    assert_equal expected_with_lang, render_document_node(with_lang)

    without_lang = NodeStub.new(
      node_type: "code_block",
      node_id: "block-code-2",
      content: "plain text",
      meta: {}
    )
    expected_without_lang = '<pre id="block-code-2" class="document-node document-node--code-block"><code>plain text</code></pre>'
    assert_equal expected_without_lang, render_document_node(without_lang)
  end

  test "renders lists with ordered and unordered styles" do
    ordered = NodeStub.new(
      node_type: "list",
      node_id: "block-list-1",
      meta: { "list_type" => "ordered" },
      children: [
        NodeStub.new(node_type: "item", children: [ NodeStub.new(node_type: "text", content: "Item 1") ])
      ]
    )
    expected_ordered = '<ol id="block-list-1" class="document-node document-node--list">' \
                       '<li class="document-node document-node--item">Item 1</li>' \
                       "</ol>"
    assert_equal expected_ordered, render_document_node(ordered)

    unordered = NodeStub.new(
      node_type: "list",
      node_id: "block-list-2",
      meta: { "list_type" => "bullet" },
      children: [
        NodeStub.new(node_type: "item", children: [ NodeStub.new(node_type: "text", content: "Item A") ])
      ]
    )
    expected_unordered = '<ul id="block-list-2" class="document-node document-node--list">' \
                         '<li class="document-node document-node--item">Item A</li>' \
                         "</ul>"
    assert_equal expected_unordered, render_document_node(unordered)
  end

  test "renders links, images, blockquotes, and thematic breaks" do
    link = NodeStub.new(
      node_type: "link",
      meta: { "url" => "https://example.com", "title" => "Example" },
      children: [ NodeStub.new(node_type: "text", content: "click") ]
    )
    assert_equal '<a href="https://example.com" title="Example" class="document-node document-node--link">click</a>', render_document_node(link)

    img = NodeStub.new(
      node_type: "image",
      node_id: "block-img",
      content: "Alt Text",
      meta: { "url" => "/logo.png", "title" => "Logo" }
    )
    assert_equal '<img src="/logo.png" alt="Alt Text" title="Logo" id="block-img" class="document-node document-node--image">', render_document_node(img)

    document = Document.create!(
      file_path: "/tmp/quote_test.md",
      content: "> quote\n",
      file_type: "markdown"
    )
    document.parse_ast_and_save!(metadata: Documents::AstParseable::ParseMetadata.new(size: 8, last_modified_at: Time.current))
    quote = document.root_node_tree.first.children.first
    assert_equal "block_quote", quote.node_type
    expected_quote = %(<blockquote id="#{quote.node_id}" class="document-node document-node--blockquote"><p id="#{quote.children.first.node_id}" class="document-node document-node--paragraph">quote</p></blockquote>)
    assert_equal expected_quote, render_document_node(quote)

    legacy_quote = NodeStub.new(
      node_type: "blockquote",
      node_id: "block-legacy",
      children: [ NodeStub.new(node_type: "text", content: "legacy") ]
    )
    assert_equal '<blockquote id="block-legacy" class="document-node document-node--blockquote">legacy</blockquote>', render_document_node(legacy_quote)

    hr = NodeStub.new(node_type: "thematic_break", node_id: "block-hr")
    assert_equal '<hr id="block-hr" class="document-node document-node--thematic-break">', render_document_node(hr)
  end

  test "renders non-collapsible callout with custom title and icon" do
    document = Document.create!(
      file_path: "/tmp/callout_test.md",
      content: "> [!NOTE] Key Architectural Decisions\n> We chose a unified model concern.\n",
      file_type: "markdown"
    )
    document.parse_ast_and_save!(metadata: Documents::AstParseable::ParseMetadata.new(size: 100, last_modified_at: Time.current))
    callout = document.root_node_tree.first.children.first

    result = render_document_node(callout)
    assert_match %r{\A<div id="block-[a-f0-9]{8}" class="document-node document-node--callout callout callout--note">}, result
    assert_includes result, '<div class="callout__header">'
    assert_includes result, '<span class="callout__icon" aria-hidden="true">'
    assert_includes result, '<span class="callout__title">Key Architectural Decisions</span>'
    assert_includes result, '<div class="callout__content">'
    assert_includes result, "We chose a unified model concern.</p>"
    refute_includes result, "<details"
    refute_includes result, "callout__fold-icon"
  end

  test "renders collapsible callout in collapsed state" do
    document = Document.create!(
      file_path: "/tmp/callout_collapsed.md",
      content: "> [!NOTE]- Detailed Analysis\n> Collapsed deep-dive.\n",
      file_type: "markdown"
    )
    document.parse_ast_and_save!(metadata: Documents::AstParseable::ParseMetadata.new(size: 100, last_modified_at: Time.current))
    callout = document.root_node_tree.first.children.first

    result = render_document_node(callout)
    assert_match %r{\A<details id="block-[a-f0-9]{8}" class="document-node document-node--callout callout callout--note callout--collapsible">}, result
    assert_includes result, '<summary class="callout__header">'
    assert_includes result, '<span class="callout__title">Detailed Analysis</span>'
    assert_includes result, '<span class="callout__fold-icon" aria-hidden="true">'
    refute_match %r{<details[^>]*\bopen\b}, result
  end

  test "renders collapsible callout in expanded state" do
    document = Document.create!(
      file_path: "/tmp/callout_expanded.md",
      content: "> [!TIP]+ Expanded Recommendation\n> Open by default.\n",
      file_type: "markdown"
    )
    document.parse_ast_and_save!(metadata: Documents::AstParseable::ParseMetadata.new(size: 100, last_modified_at: Time.current))
    callout = document.root_node_tree.first.children.first

    result = render_document_node(callout)
    assert_match %r{\A<details id="block-[a-f0-9]{8}" class="document-node document-node--callout callout callout--tip callout--collapsible" open>}, result
    assert_includes result, '<summary class="callout__header">'
    assert_includes result, '<span class="callout__title">Expanded Recommendation</span>'
    assert_includes result, '<span class="callout__fold-icon" aria-hidden="true">'
  end

  test "renders tables with header and body rows" do
    table = NodeStub.new(
      node_type: "table",
      node_id: "block-tbl",
      children: [
        NodeStub.new(
          node_type: "table_row",
          node_id: "block-row-0",
          children: [
            NodeStub.new(node_type: "table_cell", node_id: "block-cell-0", meta: { "is_header" => true }, children: [ NodeStub.new(node_type: "text", content: "Header") ])
          ]
        ),
        NodeStub.new(
          node_type: "table_row",
          node_id: "block-row-1",
          children: [
            NodeStub.new(node_type: "table_cell", node_id: "block-cell-1", meta: { "is_header" => false }, children: [ NodeStub.new(node_type: "text", content: "Value") ])
          ]
        )
      ]
    )

    expected = '<table id="block-tbl" class="document-node document-node--table">' \
               "<thead>" \
               '<tr id="block-row-0" class="document-node document-node--table-row">' \
               '<th id="block-cell-0" class="document-node document-node--table-cell document-node--table-cell-th">Header</th>' \
               "</tr>" \
               "</thead>" \
               "<tbody>" \
               '<tr id="block-row-1" class="document-node document-node--table-row">' \
               '<td id="block-cell-1" class="document-node document-node--table-cell">Value</td>' \
               "</tr>" \
               "</tbody>" \
               "</table>"

    assert_equal expected, render_document_node(table)
  end

  test "escapes dynamic HTML content and attributes to prevent XSS" do
    unsafe = NodeStub.new(
      node_type: "paragraph",
      node_id: 'p" onclick="alert(1)',
      children: [
        NodeStub.new(node_type: "text", content: "<script>alert('xss')</script>"),
        NodeStub.new(
          node_type: "link",
          meta: { "url" => 'https://example.com?a=1&b=2"', "title" => 'Title "with" quotes' },
          children: [ NodeStub.new(node_type: "text", content: "Safe & Sound") ]
        )
      ]
    )

    result = render_document_node(unsafe)
    assert_includes result, 'id="p&quot; onclick=&quot;alert(1)"'
    assert_includes result, "&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;"
    assert_includes result, 'href="https://example.com?a=1&amp;b=2&quot;"'
    assert_includes result, 'title="Title &quot;with&quot; quotes"'
    assert_includes result, "Safe &amp; Sound"
    refute_includes result, "<script>"

    unsafe_callout = NodeStub.new(
      node_type: "block_quote",
      node_id: "block-callout-xss",
      meta: {
        "callout" => {
          "type" => "note",
          "title" => "<script>alert('xss')</script>",
          "custom_title" => true
        }
      },
      children: [ NodeStub.new(node_type: "paragraph", node_id: "block-p-safe", children: [ NodeStub.new(node_type: "text", content: "Safe") ]) ]
    )
    callout_result = render_document_node(unsafe_callout)
    assert_includes callout_result, "&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;"
    refute_includes callout_result, "<script>"
  end
end
