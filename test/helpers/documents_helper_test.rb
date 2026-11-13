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

    quote = NodeStub.new(
      node_type: "blockquote",
      node_id: "block-quote",
      children: [ NodeStub.new(node_type: "text", content: "quote") ]
    )
    assert_equal '<blockquote id="block-quote" class="document-node document-node--blockquote">quote</blockquote>', render_document_node(quote)

    hr = NodeStub.new(node_type: "thematic_break", node_id: "block-hr")
    assert_equal '<hr id="block-hr" class="document-node document-node--thematic-break">', render_document_node(hr)
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
  end

  test "renders headings with 3-tier todo pills and tags" do
    # 1. Working group (amber badge modifier)
    working_node = NodeStub.new(
      node_type: "heading",
      heading_level: 2,
      node_id: "block-h2-working",
      meta: { "todo_keyword" => "WORKING", "tags" => %w[dev v1] },
      children: [ NodeStub.new(node_type: "text", content: "Active Task") ]
    )
    expected_working = '<h2 id="block-h2-working" class="document-node document-node--heading document-node--heading-2">' \
                       '<span class="document-node document-node--org-todo document-node--org-todo--working">WORKING</span> ' \
                       'Active Task' \
                       ' <span class="document-node document-node--org-tag">:dev:</span>' \
                       ' <span class="document-node document-node--org-tag">:v1:</span>' \
                       "</h2>"
    assert_equal expected_working, render_document_node(working_node)

    # 2. Done group (green badge modifier)
    done_node = NodeStub.new(
      node_type: "heading",
      heading_level: 1,
      node_id: "block-h1-done",
      meta: { "todo_keyword" => "DONE" },
      children: [ NodeStub.new(node_type: "text", content: "Finished Task") ]
    )
    expected_done = '<h1 id="block-h1-done" class="document-node document-node--heading document-node--heading-1">' \
                    '<span class="document-node document-node--org-todo document-node--org-todo--done">DONE</span> ' \
                    'Finished Task' \
                    "</h1>"
    assert_equal expected_done, render_document_node(done_node)

    # 3. Todo & Others (base badge)
    todo_node = NodeStub.new(
      node_type: "heading",
      heading_level: 3,
      node_id: "block-h3-todo",
      meta: { "todo_keyword" => "TODO" },
      children: [ NodeStub.new(node_type: "text", content: "Pending Task") ]
    )
    expected_todo = '<h3 id="block-h3-todo" class="document-node document-node--heading document-node--heading-3">' \
                    '<span class="document-node document-node--org-todo">TODO</span> ' \
                    'Pending Task' \
                    "</h3>"
    assert_equal expected_todo, render_document_node(todo_node)

    custom_node = NodeStub.new(
      node_type: "heading",
      heading_level: 3,
      node_id: "block-h3-custom",
      meta: { "todo_keyword" => "MAYBE" },
      children: [ NodeStub.new(node_type: "text", content: "Idea") ]
    )
    expected_custom = '<h3 id="block-h3-custom" class="document-node document-node--heading document-node--heading-3">' \
                      '<span class="document-node document-node--org-todo">MAYBE</span> ' \
                      'Idea' \
                      "</h3>"
    assert_equal expected_custom, render_document_node(custom_node)
  end

  test "renders underline node as u tag" do
    node = NodeStub.new(
      node_type: "underline",
      children: [ NodeStub.new(node_type: "text", content: "underlined text") ]
    )
    assert_equal '<u class="document-node document-node--underline">underlined text</u>', render_document_node(node)
  end

  test "renders block_quote with anchor id and correct tag" do
    node = NodeStub.new(
      node_type: "block_quote",
      node_id: "block-bq-1",
      children: [ NodeStub.new(node_type: "text", content: "Markdown or Org quote") ]
    )
    assert_equal '<blockquote id="block-bq-1" class="document-node document-node--blockquote">Markdown or Org quote</blockquote>', render_document_node(node)
  end

  test "renders org document title and frontmatter keywords table" do
    node = NodeStub.new(
      node_type: "document",
      meta: {
        "title" => "AIA-556 epic split plan: Voice session limits & reliability",
        "keywords" => [
          { "key" => "STARTUP", "value" => "overview" },
          { "key" => "OPTIONS", "value" => "toc:2 num:nil" }
        ]
      },
      children: [
        NodeStub.new(node_type: "paragraph", node_id: "block-p1", children: [ NodeStub.new(node_type: "text", content: "Body") ])
      ]
    )

    html = render_document_node(node)
    assert_includes html, '<h1 class="document-node document-node--org-title">AIA-556 epic split plan: Voice session limits &amp; reliability</h1>'
    assert_includes html, '<table class="document-node document-node--org-frontmatter"><tbody>'
    assert_includes html, '<th class="document-node--org-frontmatter-key">STARTUP</th><td class="document-node--org-frontmatter-value">overview</td>'
    assert_includes html, '<th class="document-node--org-frontmatter-key">OPTIONS</th><td class="document-node--org-frontmatter-value">toc:2 num:nil</td>'
    assert_includes html, '<p id="block-p1" class="document-node document-node--paragraph">Body</p>'
  end
end
