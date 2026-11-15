# frozen_string_literal: true

require "test_helper"

class OrgParserTest < ActiveSupport::TestCase
  test "parses headings with org_level, clamped heading_level, todo_keyword, and tags" do
    content = <<~ORG
      #+TODO: TODO WORKING | DONE
      * TODO First Heading :work:urgent:
      ** WORKING Second Heading
      *** DONE Third Heading
      ******* Seven Stars Heading
    ORG

    nodes = OrgParser.new(document_version_id: 1, content:).parse
    headings = nodes.select { |n| n[:node_type] == "heading" }

    assert_equal 4, headings.size

    h1 = headings[0]
    assert_equal 1, h1[:heading_level]
    assert_equal 1, h1[:meta]["org_level"]
    assert_equal "TODO", h1[:meta]["todo_keyword"]
    assert_equal %w[work urgent], h1[:meta]["tags"]
    assert h1[:node_id].start_with?("block-")

    # Children of h1 should be the title text "First Heading"
    h1_children = nodes.select { |n| n[:parent_id] == h1[:id] }
    assert_equal 1, h1_children.size
    assert_equal "text", h1_children.first[:node_type]
    assert_equal "First Heading", h1_children.first[:content]

    h2 = headings[1]
    assert_equal 2, h2[:heading_level]
    assert_equal 2, h2[:meta]["org_level"]
    assert_equal "WORKING", h2[:meta]["todo_keyword"]

    h3 = headings[2]
    assert_equal 3, h3[:heading_level]
    assert_equal 3, h3[:meta]["org_level"]
    assert_equal "DONE", h3[:meta]["todo_keyword"]

    h7 = headings[3]
    assert_equal 6, h7[:heading_level] # clamped to 6
    assert_equal 7, h7[:meta]["org_level"]
  end

  test "parses paragraphs with softbreaks and forced linebreaks" do
    content = "Line one\\\nLine two\nLine three\n"
    nodes = OrgParser.new(document_version_id: 1, content:).parse

    para = nodes.find { |n| n[:node_type] == "paragraph" }
    assert para[:node_id].start_with?("block-")

    para_children = nodes.select { |n| n[:parent_id] == para[:id] }
    types = para_children.map { |n| n[:node_type] }
    assert_equal %w[text linebreak text softbreak text], types
    assert_equal "Line one", para_children[0][:content]
    assert_equal "Line two", para_children[2][:content]
    assert_equal "Line three", para_children[4][:content]
  end

  test "parses lists including ordered, unordered, and nested lists" do
    content = <<~ORG
      - Item 1
        continuation text
      - Item 2
        - Subitem 2.1
        - Subitem 2.2
      - Item 3
      1. Step 1
      2. Step 2
    ORG

    nodes = OrgParser.new(document_version_id: 1, content:).parse
    lists = nodes.select { |n| n[:node_type] == "list" }
    assert_equal 3, lists.size

    ul_main = lists[0]
    assert_equal "unordered", ul_main[:meta]["list_type"]

    ul_nested = lists[1]
    assert_equal "unordered", ul_nested[:meta]["list_type"]

    ol = lists[2]
    assert_equal "ordered", ol[:meta]["list_type"]

    items = nodes.select { |n| n[:node_type] == "item" }
    assert_equal 7, items.size # 3 top ul + 2 sub ul + 2 ol
    assert items.all? { |i| i[:node_id].start_with?("block-") }
  end

  test "parses code blocks indented inside list items" do
    content = <<~ORG
      - *JSON Output*:
        #+BEGIN_SRC json
        {
          "thread": {
            "threadId": "mcp:..."
          }
        }
        #+END_SRC
      - Next item
    ORG

    nodes = OrgParser.new(document_version_id: 1, content:).parse
    code_block = nodes.find { |n| n[:node_type] == "code_block" }

    assert code_block, "Expected a code_block node to be created inside the list item"
    assert_equal "json", code_block[:meta]["language"]
    assert_includes code_block[:content], '"threadId": "mcp:..."'

    # Verify code_block is a child of the first item
    first_item = nodes.find { |n| n[:node_type] == "item" }
    assert_equal first_item[:id], code_block[:parent_id]
  end

  test "parses tables into table, table_row, and table_cell with metadata" do
    content = <<~ORG
      | Name | Role |
      |------+------|
      | Ada  | Dev  |
      | Bob  | Lead |
    ORG

    nodes = OrgParser.new(document_version_id: 1, content:).parse
    table = nodes.find { |n| n[:node_type] == "table" }
    rows = nodes.select { |n| n[:node_type] == "table_row" }
    cells = nodes.select { |n| n[:node_type] == "table_cell" }

    assert table[:node_id].start_with?("block-")
    assert_equal 3, rows.size # Separator row stripped, so 1 header + 2 data rows
    assert_equal [0, 1, 2], rows.map { |r| r[:meta]["row_index"] }

    assert_equal 6, cells.size
    assert_equal [true, true, false, false, false, false], cells.map { |c| c[:meta]["is_header"] }
    assert_equal [0, 1, 0, 1, 0, 1], cells.map { |c| c[:meta]["cell_index"] }
  end

  test "parses code blocks and example blocks" do
    content = <<~ORG
      #+BEGIN_SRC ruby
      def foo
        :bar
      end
      #+END_SRC

      #+BEGIN_EXAMPLE
      raw verbatim
      #+END_EXAMPLE
    ORG

    nodes = OrgParser.new(document_version_id: 1, content:).parse
    code_blocks = nodes.select { |n| n[:node_type] == "code_block" }

    assert_equal 2, code_blocks.size

    src = code_blocks[0]
    assert_equal "ruby", src[:meta]["language"]
    assert_equal "def foo\n  :bar\nend\n", src[:content]
    assert src[:node_id].start_with?("block-")

    example = code_blocks[1]
    assert_nil example[:meta]
    assert_equal "raw verbatim\n", example[:content]
    assert example[:node_id].start_with?("block-")
  end

  test "parses block quotes and nested blocks" do
    content = <<~ORG
      #+BEGIN_QUOTE
      A famous quote in org mode.
      #+END_QUOTE
    ORG

    nodes = OrgParser.new(document_version_id: 1, content:).parse
    quote = nodes.find { |n| n[:node_type] == "block_quote" }

    assert quote[:node_id].start_with?("block-")
    quote_children = nodes.select { |n| n[:parent_id] == quote[:id] }
    assert_equal 1, quote_children.size
    assert_equal "paragraph", quote_children.first[:node_type]
  end

  test "parses thematic breaks" do
    content = "-----\n"
    nodes = OrgParser.new(document_version_id: 1, content:).parse

    hr = nodes.find { |n| n[:node_type] == "thematic_break" }
    assert hr[:node_id].start_with?("block-")
  end

  test "skips drawers, comments, and in-buffer settings" do
    content = <<~ORG
      # This is a comment
      #+TITLE: Secret Project
      #+AUTHOR: Agent
      :PROPERTIES:
      :CUSTOM_ID: sec-1
      :END:
      Visible text.
    ORG

    nodes = OrgParser.new(document_version_id: 1, content:).parse
    paras = nodes.select { |n| n[:node_type] == "paragraph" }

    assert_equal 1, paras.size
    text_node = nodes.find { |n| n[:parent_id] == paras.first[:id] }
    assert_equal "Visible text.", text_node[:content]
  end

  test "parses links with and without labels" do
    content = "[[https://example.com][Example Site]] and [[https://openai.com]]"
    nodes = OrgParser.new(document_version_id: 1, content:).parse

    links = nodes.select { |n| n[:node_type] == "link" }
    assert_equal 2, links.size

    assert_equal "https://example.com", links[0][:meta]["url"]
    label_node = nodes.find { |n| n[:parent_id] == links[0][:id] }
    assert_equal "Example Site", label_node[:content]

    assert_equal "https://openai.com", links[1][:meta]["url"]
    url_node = nodes.find { |n| n[:parent_id] == links[1][:id] }
    assert_equal "https://openai.com", url_node[:content]
  end

  test "adversarial emphasis grammar fixtures" do
    # 1. "* not bold" -> plain text
    n1 = OrgParser.new(document_version_id: 1, content: "* not bold").parse
    refute n1.any? { |n| n[:node_type] == "strong" }

    # 2. "2 * 3 * 4" -> plain text
    n2 = OrgParser.new(document_version_id: 1, content: "2 * 3 * 4").parse
    refute n2.any? { |n| n[:node_type] == "strong" }

    # 3. "a*b*c" -> plain text
    n3 = OrgParser.new(document_version_id: 1, content: "a*b*c").parse
    refute n3.any? { |n| n[:node_type] == "strong" }

    # 4. "_under score_" -> plain text
    n4 = OrgParser.new(document_version_id: 1, content: "_under score_").parse
    refute n4.any? { |n| n[:node_type] == "underline" }

    # 5. "*bold*. Trailing sentence." -> bold node parsed
    n5 = OrgParser.new(document_version_id: 1, content: "*bold*. Trailing sentence.").parse
    strong_node = n5.find { |n| n[:node_type] == "strong" }
    assert strong_node
    strong_text = n5.find { |n| n[:parent_id] == strong_node[:id] }
    assert_equal "bold", strong_text[:content]

    # 6. "~code with /this/~" -> code node with verbatim body
    n6 = OrgParser.new(document_version_id: 1, content: "~code with /this/~").parse
    code_node = n6.find { |n| n[:node_type] == "code" }
    assert code_node
    assert_equal "code with /this/", code_node[:content]
    refute n6.any? { |n| n[:node_type] == "emph" }

    # 7. "#+BEGIN_SRC" body containing "*bold*" -> verbatim block, no inlines
    n7 = OrgParser.new(document_version_id: 1, content: "#+BEGIN_SRC\n*bold*\n#+END_SRC").parse
    code_block = n7.find { |n| n[:node_type] == "code_block" }
    assert code_block
    assert_equal "*bold*\n", code_block[:content]
    refute n7.any? { |n| n[:node_type] == "strong" }
  end

  test "satisfies node identity contract" do
    content = <<~ORG
      * Heading
      Paragraph with *bold* text.
    ORG

    nodes = OrgParser.new(document_version_id: 42, content:).parse

    # 1. Root document exists
    doc_node = nodes.find { |n| n[:node_type] == "document" }
    assert doc_node
    assert_nil doc_node[:parent_id]
    assert_nil doc_node[:node_id]

    # 2. All nodes have id and document_version_id
    assert nodes.all? { |n| n[:id].present? && n[:document_version_id] == 42 }

    # 3. All non-root nodes have valid parent_id
    ids = nodes.map { |n| n[:id] }.to_set
    non_roots = nodes.reject { |n| n[:node_type] == "document" }
    assert non_roots.all? { |n| ids.include?(n[:parent_id]) }

    # 4. Positions are 0-based per parent
    nodes.group_by { |n| n[:parent_id] }.each do |_pid, children|
      assert_equal (0...children.size).to_a, children.map { |c| c[:position] }
    end

    # 5. Block-level nodes have block- prefix, inlines have nil node_id
    OrgParser::BLOCK_LEVEL_TYPES.each do |block_type|
      matching = nodes.select { |n| n[:node_type] == block_type }
      assert matching.all? { |n| n[:node_id]&.start_with?("block-") }
    end

    inlines = nodes.select { |n| %w[text strong emph underline code link].include?(n[:node_type]) }
    assert inlines.all? { |n| n[:node_id].nil? }
  end

  test "extracts file-level TITLE and keywords into document metadata and keeps them out of body" do
    content = <<~ORG
      #+TITLE: AIA-556 epic split plan: Voice session limits & reliability
      #+STARTUP: overview
      #+OPTIONS: toc:2 num:nil
      #+TODO: TODO(t) | DONE(d)

      * Body Heading
      Body paragraph.
    ORG

    nodes = OrgParser.new(document_version_id: 1, content:).parse
    doc_node = nodes.find { |n| n[:node_type] == "document" }

    assert_equal "AIA-556 epic split plan: Voice session limits & reliability", doc_node[:meta]["title"]
    assert_equal [
      { "key" => "STARTUP", "value" => "overview" },
      { "key" => "OPTIONS", "value" => "toc:2 num:nil" },
      { "key" => "TODO", "value" => "TODO(t) | DONE(d)" }
    ], doc_node[:meta]["keywords"]

    body_children = nodes.select { |n| n[:parent_id] == doc_node[:id] }
    assert_equal %w[heading paragraph], body_children.map { |n| n[:node_type] }

    lowercase_nodes = OrgParser.new(document_version_id: 1, content: "#+title: Lowercase Title\n").parse
    lowercase_doc = lowercase_nodes.find { |n| n[:node_type] == "document" }
    assert_equal "Lowercase Title", lowercase_doc[:meta]["title"]
  end

  test "parses inline verbatim containing internal equals in paragraph, heading, and list item" do
    content = <<~ORG
      * Check =MAX_CALL_SECONDS = 2700= as the task hard timeout

      =MAX_CALL_SECONDS = 2700= as the task hard timeout

      - Set =MAX_CALL_SECONDS = 2700= as the task hard timeout
    ORG

    nodes = OrgParser.new(document_version_id: 1, content:).parse

    heading = nodes.find { |n| n[:node_type] == "heading" }
    heading_code = nodes.find { |n| n[:parent_id] == heading[:id] && n[:node_type] == "code" }
    assert heading_code
    assert_equal "MAX_CALL_SECONDS = 2700", heading_code[:content]

    doc_node = nodes.find { |n| n[:node_type] == "document" }
    para = nodes.find { |n| n[:parent_id] == doc_node[:id] && n[:node_type] == "paragraph" }
    para_code = nodes.find { |n| n[:parent_id] == para[:id] && n[:node_type] == "code" }
    assert para_code
    assert_equal "MAX_CALL_SECONDS = 2700", para_code[:content]

    item = nodes.find { |n| n[:node_type] == "item" }
    item_para = nodes.find { |n| n[:parent_id] == item[:id] && n[:node_type] == "paragraph" }
    item_code = nodes.find { |n| n[:parent_id] == item_para[:id] && n[:node_type] == "code" }
    assert item_code
    assert_equal "MAX_CALL_SECONDS = 2700", item_code[:content]
  end

  test "parses bold containing verbatim using the buddy doc repro line" do
    repro = "2. *=hc ls= vs =hc get= schema discrepancy*: In =hc ls --all | cat= on v0.1.21, each item only had ={address, agent, cwd, state, status, turn, where}=—it *omitted =labels=*, =name=, and =foreground.cwd= (unlike =hc get=, which includes full =labels=)."

    nodes = OrgParser.new(document_version_id: 1, content: repro).parse
    item = nodes.find { |n| n[:node_type] == "item" }
    para = nodes.find { |n| n[:parent_id] == item[:id] && n[:node_type] == "paragraph" }
    para_children = nodes.select { |n| n[:parent_id] == para[:id] }

    first_strong = para_children.first
    assert_equal "strong", first_strong[:node_type]
    assert_equal para[:id], first_strong[:parent_id]

    strong_children = nodes.select { |n| n[:parent_id] == first_strong[:id] }
    assert_equal %w[code text code text], strong_children.map { |n| n[:node_type] }
    assert_equal [ "hc ls", " vs ", "hc get", " schema discrepancy" ], strong_children.map { |n| n[:content] }

    assert_equal "text", para_children[1][:node_type]
    assert para_children[1][:content].start_with?(": In ")

    code_contents = para_children.select { |n| n[:node_type] == "code" }.map { |n| n[:content] }
    assert_includes code_contents, "hc ls --all | cat"
    assert_includes code_contents, "foreground.cwd"
    assert_includes code_contents, "hc get"
    assert_includes code_contents, "labels"

    text_nodes = nodes.select { |n| n[:node_type] == "text" }
    refute text_nodes.any? { |n| n[:content].include?("*") || n[:content].include?("=") }
  end

  test "parses bold whose body starts with a verbatim span" do
    nodes = OrgParser.new(document_version_id: 1, content: "*=cmd= flag*").parse
    para = nodes.find { |n| n[:node_type] == "paragraph" }
    strong = nodes.find { |n| n[:parent_id] == para[:id] && n[:node_type] == "strong" }
    assert strong

    children = nodes.select { |n| n[:parent_id] == strong[:id] }
    assert_equal %w[code text], children.map { |n| n[:node_type] }
    assert_equal [ "cmd", " flag" ], children.map { |n| n[:content] }
  end

  test "parses code inside italic and inside underline" do
    nodes = OrgParser.new(document_version_id: 1, content: "/run ~foo~ now/ and _~bar~_").parse
    para = nodes.find { |n| n[:node_type] == "paragraph" }

    emph = nodes.find { |n| n[:parent_id] == para[:id] && n[:node_type] == "emph" }
    assert emph
    emph_children = nodes.select { |n| n[:parent_id] == emph[:id] }
    assert_equal %w[text code text], emph_children.map { |n| n[:node_type] }
    assert_equal [ "run ", "foo", " now" ], emph_children.map { |n| n[:content] }

    underline = nodes.find { |n| n[:parent_id] == para[:id] && n[:node_type] == "underline" }
    assert underline
    underline_children = nodes.select { |n| n[:parent_id] == underline[:id] }
    assert_equal %w[code], underline_children.map { |n| n[:node_type] }
    assert_equal "bar", underline_children.first[:content]
  end

  test "parses link label containing verbatim" do
    nodes = OrgParser.new(document_version_id: 1, content: "[[https://example.com][see =hc ls= docs]]").parse
    para = nodes.find { |n| n[:node_type] == "paragraph" }
    link = nodes.find { |n| n[:parent_id] == para[:id] && n[:node_type] == "link" }
    assert link

    link_children = nodes.select { |n| n[:parent_id] == link[:id] }
    assert_equal %w[text code text], link_children.map { |n| n[:node_type] }
    assert_equal [ "see ", "hc ls", " docs" ], link_children.map { |n| n[:content] }
  end

  test "plain text with no markup parses to a single text node" do
    nodes = OrgParser.new(document_version_id: 1, content: "Just plain text with no markup.").parse
    para = nodes.find { |n| n[:node_type] == "paragraph" }
    children = nodes.select { |n| n[:parent_id] == para[:id] }

    assert_equal %w[text], children.map { |n| n[:node_type] }
    assert_equal "Just plain text with no markup.", children.first[:content]
  end

  test "parses full buddy doc line 323 with em dash boundary and nested omitted labels" do
    line_323 = "2. *=hc ls= vs =hc get= schema discrepancy*: In =hc ls --all | cat= on v0.1.21, each item only had ={address, agent, cwd, state, status, turn, where}=—it *omitted =labels=*, =name=, and =foreground.cwd= (unlike =hc get=, which includes full =labels=)."

    nodes = OrgParser.new(document_version_id: 1, content: line_323).parse
    item = nodes.find { |n| n[:node_type] == "item" }
    para = nodes.find { |n| n[:parent_id] == item[:id] && n[:node_type] == "paragraph" }
    para_children = nodes.select { |n| n[:parent_id] == para[:id] }

    strong_nodes = para_children.select { |n| n[:node_type] == "strong" }
    assert_equal 2, strong_nodes.size

    omitted_strong = strong_nodes[1]
    omitted_children = nodes.select { |n| n[:parent_id] == omitted_strong[:id] }
    assert_equal %w[text code], omitted_children.map { |n| n[:node_type] }
    assert_equal [ "omitted ", "labels" ], omitted_children.map { |n| n[:content] }

    address_code = para_children.find { |n| n[:node_type] == "code" && n[:content].start_with?("{address") }
    assert address_code
    assert_equal "{address, agent, cwd, state, status, turn, where}", address_code[:content]
    refute_includes address_code[:content], "\u2014"
    refute_includes address_code[:content], "omitted"

    text_nodes = nodes.select { |n| n[:node_type] == "text" }
    refute text_nodes.any? { |n| n[:content].include?("*") || n[:content].include?("=") }
  end

  test "closes verbatim span on em dash, en dash, ellipsis, asterisk, and closing parenthesis" do
    cases = {
      "=foo=—bar" => "foo",
      "=foo=–bar" => "foo",
      "=foo=…bar" => "foo",
      "*=foo=*" => "foo",
      "(=foo=)" => "foo"
    }

    cases.each do |input, expected|
      nodes = OrgParser.new(document_version_id: 1, content: input).parse
      code = nodes.find { |n| n[:node_type] == "code" }
      assert code, "Expected code node for #{input.inspect}"
      assert_equal expected, code[:content]
    end
  end

  test "does not parse mid-word delimiters a*b, x/y, or 2=3" do
    %w[a*b x/y 2=3].each do |input|
      nodes = OrgParser.new(document_version_id: 1, content: input).parse
      refute nodes.any? { |n| %w[strong emph code].include?(n[:node_type]) },
             "Expected no strong/emph/code node for #{input.inspect}"
    end
  end
end
