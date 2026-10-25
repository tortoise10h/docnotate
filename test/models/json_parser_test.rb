require "test_helper"

class JsonParserTest < ActiveSupport::TestCase
  include JsonViewerHelper
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::OutputSafetyHelper

  test "parses nested JSON into structural containers and leaf line blocks" do
    json_text = <<~JSON
      {
        "name": "DocNotate",
        "version": 1,
        "active": true,
        "tags": [
          "editor",
          "viewer"
        ],
        "empty_obj": {},
        "empty_arr": []
      }
    JSON

    nodes = JsonParser.new(document_version_id: 1, content: json_text).parse

    root_obj = nodes.find { |n| n[:node_type] == "json_object" && n[:parent_id].nil? }
    assert_not_nil root_obj
    assert_nil root_obj[:node_id]
    assert_equal "6 keys", root_obj[:meta]["summary"]

    open_node = nodes.find { |n| n[:parent_id] == root_obj[:id] && n[:node_type] == "json_open" }
    assert_not_nil open_node
    assert open_node[:node_id].start_with?("block-")
    assert_equal "{", open_node[:content]

    close_node = nodes.find { |n| n[:parent_id] == root_obj[:id] && n[:node_type] == "json_close" }
    assert_not_nil close_node
    assert close_node[:node_id].start_with?("block-")
    assert_equal "}", close_node[:content]

    primitives = nodes.select { |n| n[:node_type] == "json_primitive" }
    assert primitives.all? { |p| p[:node_id].start_with?("block-") }

    name_node = primitives.find { |p| p[:meta]["key"] == "name" }
    assert_equal "\"name\": \"DocNotate\",", name_node[:content]
    assert_equal "string", name_node[:meta]["value_type"]
    assert name_node[:meta]["trailing_comma"]

    version_node = primitives.find { |p| p[:meta]["key"] == "version" }
    assert_equal "\"version\": 1,", version_node[:content]
    assert_equal "number", version_node[:meta]["value_type"]

    active_node = primitives.find { |p| p[:meta]["key"] == "active" }
    assert_equal "\"active\": true,", active_node[:content]
    assert_equal "boolean", active_node[:meta]["value_type"]

    tags_array = nodes.find { |n| n[:node_type] == "json_array" }
    assert_not_nil tags_array
    assert_nil tags_array[:node_id]
    assert_equal "2 items", tags_array[:meta]["summary"]

    empty_obj_node = primitives.find { |p| p[:meta]["key"] == "empty_obj" }
    assert_equal "\"empty_obj\": {},", empty_obj_node[:content]
    assert_equal "object", empty_obj_node[:meta]["value_type"]

    empty_arr_node = primitives.find { |p| p[:meta]["key"] == "empty_arr" }
    assert_equal "\"empty_arr\": []", empty_arr_node[:content]
    assert_equal "array", empty_arr_node[:meta]["value_type"]
    assert_not empty_arr_node[:meta]["trailing_comma"]
  end

  test "render_json_tokens produces plain text matching node content exactly" do
    json_text = '{"title": "DocNotate", "score": 9.5, "verified": false, "null_val": null, "items": [1, 2]}'
    nodes = JsonParser.new(document_version_id: 1, content: json_text).parse

    nodes.each do |node_attrs|
      next if node_attrs[:content].nil?

      fake_node = Struct.new(:node_type, :content, :meta).new(
        node_attrs[:node_type],
        node_attrs[:content],
        node_attrs[:meta]
      )
      rendered = render_json_tokens(fake_node)
      plain_text = ActionController::Base.helpers.strip_tags(rendered)

      assert_equal node_attrs[:content], plain_text, "Mismatch for #{node_attrs[:node_type]}: #{node_attrs[:content]}"
    end
  end

  test "handles malformed JSON with an error banner and raw content fallback lines" do
    malformed = "{\n  \"invalid\": \n}"
    nodes = JsonParser.new(document_version_id: 1, content: malformed).parse

    error_node = nodes.find { |n| n[:node_type] == "json_error" }
    assert_not_nil error_node
    assert_nil error_node[:node_id]
    assert error_node[:meta]["error_message"].present?

    raw_lines = nodes.select { |n| n[:node_type] == "json_raw_line" }
    assert_equal 3, raw_lines.size
    assert raw_lines.all? { |line| line[:node_id].start_with?("block-") }
    assert_equal ["{", "  \"invalid\": ", "}"], raw_lines.map { |line| line[:content] }
  end
end
