class JsonParser
  def initialize(document_version_id:, content:)
    @document_version_id = document_version_id
    @content = content
  end

  def parse
    parsed = JSON.parse(@content)
    @nodes = []
    @now = Time.current

    process_value(parsed, key: nil, parent_id: nil, position: 0, depth: 0, trailing_comma: false)
    @nodes
  rescue JSON::ParserError => e
    build_fallback_nodes(e.message)
  end

  private

  def process_value(value, key:, parent_id:, position:, depth:, trailing_comma:)
    case value
    when Hash
      process_hash(value, key:, parent_id:, position:, depth:, trailing_comma:)
    when Array
      process_array(value, key:, parent_id:, position:, depth:, trailing_comma:)
    else
      process_primitive(value, key:, parent_id:, position:, depth:, trailing_comma:)
    end
  end

  def process_hash(hash, key:, parent_id:, position:, depth:, trailing_comma:)
    if hash.empty?
      content = build_line_content(key:, value_repr: "{}", trailing_comma:)
      @nodes << {
        id: SecureRandom.uuid_v7,
        document_version_id: @document_version_id,
        parent_id: parent_id,
        position: position,
        node_type: "json_primitive",
        content: content,
        heading_level: nil,
        meta: { "depth" => depth, "key" => key, "value_type" => "object", "value_json" => "{}", "trailing_comma" => trailing_comma },
        node_id: unique_block_id,
        created_at: @now,
        updated_at: @now
      }
      return
    end

    container_id = SecureRandom.uuid_v7
    summary = "#{hash.size} #{'key'.pluralize(hash.size)}"

    @nodes << {
      id: container_id,
      document_version_id: @document_version_id,
      parent_id: parent_id,
      position: position,
      node_type: "json_object",
      content: nil,
      heading_level: nil,
      meta: { "depth" => depth, "summary" => summary },
      node_id: nil,
      created_at: @now,
      updated_at: @now
    }

    open_content = build_line_content(key:, value_repr: "{", trailing_comma: false)
    @nodes << {
      id: SecureRandom.uuid_v7,
      document_version_id: @document_version_id,
      parent_id: container_id,
      position: 0,
      node_type: "json_open",
      content: open_content,
      heading_level: nil,
      meta: { "depth" => depth, "key" => key, "bracket" => "{", "summary" => summary },
      node_id: unique_block_id,
      created_at: @now,
      updated_at: @now
    }

    hash.each_with_index do |(child_key, child_val), index|
      is_last = (index == hash.size - 1)
      process_value(
        child_val,
        key: child_key,
        parent_id: container_id,
        position: index + 1,
        depth: depth + 1,
        trailing_comma: !is_last
      )
    end

    close_content = "}" + (trailing_comma ? "," : "")
    @nodes << {
      id: SecureRandom.uuid_v7,
      document_version_id: @document_version_id,
      parent_id: container_id,
      position: hash.size + 1,
      node_type: "json_close",
      content: close_content,
      heading_level: nil,
      meta: { "depth" => depth, "bracket" => "}", "trailing_comma" => trailing_comma },
      node_id: unique_block_id,
      created_at: @now,
      updated_at: @now
    }
  end

  def process_array(array, key:, parent_id:, position:, depth:, trailing_comma:)
    if array.empty?
      content = build_line_content(key:, value_repr: "[]", trailing_comma:)
      @nodes << {
        id: SecureRandom.uuid_v7,
        document_version_id: @document_version_id,
        parent_id: parent_id,
        position: position,
        node_type: "json_primitive",
        content: content,
        heading_level: nil,
        meta: { "depth" => depth, "key" => key, "value_type" => "array", "value_json" => "[]", "trailing_comma" => trailing_comma },
        node_id: unique_block_id,
        created_at: @now,
        updated_at: @now
      }
      return
    end

    container_id = SecureRandom.uuid_v7
    summary = "#{array.size} #{'item'.pluralize(array.size)}"

    @nodes << {
      id: container_id,
      document_version_id: @document_version_id,
      parent_id: parent_id,
      position: position,
      node_type: "json_array",
      content: nil,
      heading_level: nil,
      meta: { "depth" => depth, "summary" => summary },
      node_id: nil,
      created_at: @now,
      updated_at: @now
    }

    open_content = build_line_content(key:, value_repr: "[", trailing_comma: false)
    @nodes << {
      id: SecureRandom.uuid_v7,
      document_version_id: @document_version_id,
      parent_id: container_id,
      position: 0,
      node_type: "json_open",
      content: open_content,
      heading_level: nil,
      meta: { "depth" => depth, "key" => key, "bracket" => "[", "summary" => summary },
      node_id: unique_block_id,
      created_at: @now,
      updated_at: @now
    }

    array.each_with_index do |item, index|
      is_last = (index == array.size - 1)
      process_value(
        item,
        key: nil,
        parent_id: container_id,
        position: index + 1,
        depth: depth + 1,
        trailing_comma: !is_last
      )
    end

    close_content = "]" + (trailing_comma ? "," : "")
    @nodes << {
      id: SecureRandom.uuid_v7,
      document_version_id: @document_version_id,
      parent_id: container_id,
      position: array.size + 1,
      node_type: "json_close",
      content: close_content,
      heading_level: nil,
      meta: { "depth" => depth, "bracket" => "]", "trailing_comma" => trailing_comma },
      node_id: unique_block_id,
      created_at: @now,
      updated_at: @now
    }
  end

  def process_primitive(value, key:, parent_id:, position:, depth:, trailing_comma:)
    value_type = determine_value_type(value)
    value_json = JSON.generate(value)
    content = build_line_content(key:, value_repr: value_json, trailing_comma:)

    @nodes << {
      id: SecureRandom.uuid_v7,
      document_version_id: @document_version_id,
      parent_id: parent_id,
      position: position,
      node_type: "json_primitive",
      content: content,
      heading_level: nil,
      meta: {
        "depth" => depth,
        "key" => key,
        "value_type" => value_type,
        "value_json" => value_json,
        "trailing_comma" => trailing_comma
      },
      node_id: unique_block_id,
      created_at: @now,
      updated_at: @now
    }
  end

  def determine_value_type(value)
    case value
    when String then "string"
    when Numeric then "number"
    when TrueClass, FalseClass then "boolean"
    when NilClass then "null"
    else "string"
    end
  end

  def build_line_content(key:, value_repr:, trailing_comma:)
    line = key.present? ? "\"#{key}\": #{value_repr}" : value_repr
    line = "#{line}," if trailing_comma
    line
  end

  def build_fallback_nodes(error_message)
    nodes = []
    now = Time.current

    nodes << {
      id: SecureRandom.uuid_v7,
      document_version_id: @document_version_id,
      parent_id: nil,
      position: 0,
      node_type: "json_error",
      content: nil,
      heading_level: nil,
      meta: { "error_message" => error_message },
      node_id: nil,
      created_at: now,
      updated_at: now
    }

    lines = @content.to_s.lines
    lines = [""] if lines.empty?
    lines.each_with_index do |line, index|
      nodes << {
        id: SecureRandom.uuid_v7,
        document_version_id: @document_version_id,
        parent_id: nil,
        position: index + 1,
        node_type: "json_raw_line",
        content: line.chomp,
        heading_level: nil,
        meta: { "line_number" => index + 1 },
        node_id: unique_block_id,
        created_at: now,
        updated_at: now
      }
    end

    nodes
  end

  def unique_block_id
    "block-#{SecureRandom.hex(4)}"
  end
end
