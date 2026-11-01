require "test_helper"

class MarkdownParserTest < ActiveSupport::TestCase
  test "recognizes table rows and cells with positional metadata" do
    nodes = MarkdownParser.new(
      document_version_id: 1,
      content: "| Name | Age |\n| --- | --- |\n| Ada | 36 |\n"
    ).parse

    table = nodes.find { |node| node[:node_type] == "table" }
    rows = nodes.select { |node| node[:node_type] == "table_row" }
    cells = nodes.select { |node| node[:node_type] == "table_cell" }

    assert table[:node_id].start_with?("block-")
    assert_equal 2, rows.size
    assert_equal [ 0, 1 ], rows.map { |row| row[:meta]["row_index"] }
    assert_equal 4, cells.size
    assert_equal [ 0, 1, 0, 1 ], cells.map { |cell| cell[:meta]["cell_index"] }
    assert_equal [ true, true, false, false ], cells.map { |cell| cell[:meta]["is_header"] }
    assert cells.all? { |cell| cell[:node_id].start_with?("block-") }
  end

  test "captures the fence language on code blocks" do
    nodes = MarkdownParser.new(
      document_version_id: 1,
      content: "```mermaid\nflowchart TD\n  A --> B\n```\n"
    ).parse

    code_block = nodes.find { |node| node[:node_type] == "code_block" }

    assert_equal "mermaid", code_block[:meta]["language"]
    assert code_block[:node_id].start_with?("block-")
  end

  test "captures callout metadata on block_quote nodes and normalizes AST" do
    nodes = MarkdownParser.new(
      document_version_id: 1,
      content: "> [!NOTE] Architecture Decisions\n> We chose a unified model.\n"
    ).parse

    bq = nodes.find { |node| node[:node_type] == "block_quote" }
    assert_not_nil bq
    assert bq[:node_id].start_with?("block-")
    assert_equal(
      { "type" => "note", "title" => "Architecture Decisions", "custom_title" => true, "collapsible" => nil },
      bq[:meta]["callout"]
    )

    # Paragraph child contains only the body text, not the marker line
    p_node = nodes.find { |node| node[:node_type] == "paragraph" }
    assert_equal bq[:id], p_node[:parent_id]
    text_node = nodes.find { |node| node[:node_type] == "text" && node[:parent_id] == p_node[:id] }
    assert_equal "We chose a unified model.", text_node[:content]
  end

  test "leaves plain blockquotes without callout metadata" do
    nodes = MarkdownParser.new(
      document_version_id: 1,
      content: "> Regular quote\n"
    ).parse

    bq = nodes.find { |node| node[:node_type] == "block_quote" }
    assert_not_nil bq
    assert_nil bq[:meta]

    text_node = nodes.find { |node| node[:node_type] == "text" }
    assert_equal "Regular quote", text_node[:content]
  end

  test "leaves unknown alert types as standard blockquotes" do
    nodes = MarkdownParser.new(
      document_version_id: 1,
      content: "> [!UNKNOWN] Foo\n"
    ).parse

    bq = nodes.find { |node| node[:node_type] == "block_quote" }
    assert_not_nil bq
    assert_nil bq[:meta]

    text_node = nodes.find { |node| node[:node_type] == "text" }
    assert_equal "[!UNKNOWN] Foo", text_node[:content]
  end
end
