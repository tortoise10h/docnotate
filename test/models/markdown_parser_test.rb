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
end
