# frozen_string_literal: true

class OrgParser
  BLOCK_LEVEL_TYPES = %w[
    paragraph heading code_block list item
    block_quote thematic_break table table_row table_cell
  ].freeze

  DEFAULT_TODO_KEYWORDS = %w[
    TODO DONE WORKING DOING GOING IN-PROGRESS IN_PROGRESS
    NEXT WAITING WAIT HOLD CANCELLED CANCELED SOMEDAY MAYBE
    BLOCKED WIP FIXED VERIFIED
  ].freeze

  SPACE_BYTE = " ".ord
  TAB_BYTE = "\t".ord
  STAR_BYTE = "*".ord
  COLON_BYTE = ":".ord
  HASH_BYTE = "#".ord
  DASH_BYTE = "-".ord
  PLUS_BYTE = "+".ord
  PIPE_BYTE = "|".ord
  ZERO_BYTE = "0".ord
  NINE_BYTE = "9".ord

  TODO_DIRECTIVE_REGEX = /\A#\+(?:TODO|SEQ_TODO|TYP_TODO):\s*(.*)\z/i
  DRAWER_OPEN_REGEX = /\A:[a-zA-Z0-9_-]+:\s*\z/
  FILE_KEYWORD_REGEX = /\A#\+([a-zA-Z0-9_-]+):(.*)\z/
  BEGIN_BLOCK_REGEX = /\A#\+BEGIN_(SRC|EXAMPLE|QUOTE)(?:\s+([^\n]+))?\s*\z/i
  HEADING_TAGS_REGEX = /\s+:([a-zA-Z0-9_@#%]+(?::[a-zA-Z0-9_@#%]+)*):\s*\z/
  HEADING_TODO_REGEX = /\A([A-Z][A-Z0-9_-]*)(?:\s+(.*)|\z)/
  TABLE_SEPARATOR_REGEX = /\A\|[-+ ]+\|\z/
  ORDERED_LIST_REGEX = /\A(\d+[.)])\s+(.*)\z/
  FORCED_LINEBREAK_REGEX = /\\{1,2}\s*\z/

  DELIMITED_TYPES = {
    "~" => "code",
    "=" => "code",
    "*" => "strong",
    "/" => "emph",
    "_" => "underline"
  }.freeze

  # Matches only valid inline openers ([[ links, or ~ = * / _ at a valid pre-boundary
  # followed by a non-space, non-duplicate char) so C-level scanning skips plain text,
  # snake_case, URLs, and spaced operators like "a * b" without entering the Ruby loop.
  # Add new inline syntax openers here and in DELIMITED_TYPES / match_inline_at.
  INLINE_TRIGGER_REGEX = /\[\[|(?<=\A|[\s({'\"\[])(?:~(?![\s~])|=(?![\s=])|\*(?![\s*])|\/(?![\s\/])|_(?![\s_]))/
  INLINE_POST_CHAR_REGEX = /\A(?:\s|[[:punct:]]|\})\z/
  WHITESPACE_CHAR_REGEX = /\A\s\z/
  LINK_ANCHORED_REGEX = /\G\[\[([^\]]+)\](?:\[([^\]]+)\])?\]/

  InternalNode = Struct.new(:type, :content, :meta, :children, :heading_level, keyword_init: true) do
    def initialize(**kwargs)
      super
      self.children ||= []
    end
  end

  def initialize(document_version_id:, content:)
    @document_version_id = document_version_id
    @content = content.to_s
    @todo_keywords = Set.new(DEFAULT_TODO_KEYWORDS)
    extract_custom_todo_keywords
  end

  def parse
    @now = Time.current
    @document_title = nil
    @file_keywords = []

    lines = @content.lines(chomp: true)
    children = parse_blocks(lines, top_level: true)

    meta = {}
    meta["title"] = @document_title if @document_title.present?
    meta["keywords"] = @file_keywords if @file_keywords.any?
    root = InternalNode.new(type: "document", meta: meta.presence, children:)

    @flat_nodes = []
    flatten_node(root, parent_id: nil, position: 0)
    @flat_nodes
  end

  private

  def extract_custom_todo_keywords
    @content.each_line(chomp: true) do |line|
      trimmed, = trim_leading(line)
      next unless trimmed.start_with?("#+")

      if (match = trimmed.match(TODO_DIRECTIVE_REGEX))
        tokens = match[1].split.reject { |t| t == "|" || t.start_with?("(") }
        tokens.each { |token| @todo_keywords << token.upcase }
      end
    end
  end

  def parse_blocks(lines, top_level: false)
    nodes = []
    i = 0
    total = lines.length

    while i < total
      line = lines[i]
      trimmed, indent = trim_leading(line)

      # Empty line
      if trimmed.empty?
        i += 1
        next
      end

      first_byte = trimmed.getbyte(0)

      # 1. Headings (* at column 0 followed by whitespace or EOL)
      if indent.zero? && first_byte == STAR_BYTE && (star_count = heading_star_count(line))
        nodes << parse_heading(line, star_count)
        i += 1
        next
      end

      # 2. Drawers (:NAME: ... :END:)
      if first_byte == COLON_BYTE && trimmed.match?(DRAWER_OPEN_REGEX)
        i = skip_drawer(lines, i + 1)
        next
      end

      # 3. Comments, file keywords, and #+BEGIN_* blocks
      if first_byte == HASH_BYTE
        if trimmed.start_with?("#+")
          if (block_match = match_begin_block(trimmed))
            node, i = parse_delimited_block(lines, i, block_match, indent)
            nodes << node
            next
          elsif !trimmed.match?(/\A#\+END_/i) && (kw_match = trimmed.match(FILE_KEYWORD_REGEX))
            record_file_keyword(kw_match[1], kw_match[2].strip) if top_level
            i += 1
            next
          end
        elsif comment_line?(trimmed)
          i += 1
          next
        end
      end

      # 4. Thematic breaks (5+ dashes)
      if first_byte == DASH_BYTE && thematic_break?(trimmed)
        nodes << InternalNode.new(type: "thematic_break")
        i += 1
        next
      end

      # 5. Tables
      if first_byte == PIPE_BYTE
        table_node, i = parse_table_block(lines, i)
        nodes << table_node if table_node
        next
      end

      # 6. Lists
      if list_bullet_match(line, trimmed:, indent:)
        list_node, i = parse_list_block(lines, i)
        nodes << list_node if list_node
        next
      end

      # 7. Paragraph
      para_lines = []
      while i < total
        cur_line = lines[i]
        cur_trimmed, cur_indent = trim_leading(cur_line)
        break if cur_trimmed.empty?
        break if block_boundary?(cur_line, trimmed: cur_trimmed, indent: cur_indent)

        para_lines << cur_line
        i += 1
      end

      nodes << build_paragraph_node(para_lines) if para_lines.any?
    end

    nodes
  end

  def trim_leading(line)
    first_byte = line.getbyte(0)
    if first_byte && first_byte <= SPACE_BYTE
      trimmed = line.lstrip
      [ trimmed, line.length - trimmed.length ]
    else
      [ line, 0 ]
    end
  end

  def heading_star_count(line)
    return nil unless line.getbyte(0) == STAR_BYTE

    count = 1
    count += 1 while line.getbyte(count) == STAR_BYTE
    next_byte = line.getbyte(count)
    (next_byte.nil? || next_byte == SPACE_BYTE || next_byte == TAB_BYTE) ? count : nil
  end

  def parse_heading(line, org_level)
    raw_text = (line.byteslice(org_level..) || "").strip
    heading_level = [ org_level, 6 ].min
    meta = { "org_level" => org_level }

    # Parse tags on header, eg: ":company:project:"
    if (tag_match = raw_text.match(HEADING_TAGS_REGEX))
      tags = tag_match[1].split(":")
      raw_text = raw_text[0...tag_match.begin(0)].strip
      meta["tags"] = tags if tags.any?
    end

    # TODO header, eg: "TODO work on something"
    if (todo_match = raw_text.match(HEADING_TODO_REGEX))
      candidate = todo_match[1]
      if @todo_keywords.include?(candidate)
        meta["todo_keyword"] = candidate
        raw_text = (todo_match[2] || "").strip
      end
    end

    children = raw_text.empty? ? [] : parse_inlines(raw_text)
    InternalNode.new(type: "heading", heading_level:, meta:, children:)
  end

  def skip_drawer(lines, i)
    total = lines.length
    i += 1 while i < total && !lines[i].strip.casecmp?(":END:")
    i < total ? i + 1 : i
  end

  def comment_line?(trimmed)
    trimmed.length == 1 || trimmed.getbyte(1) <= SPACE_BYTE
  end

  def thematic_break?(trimmed)
    trimmed.start_with?("-----") && trimmed.rstrip.delete("-").empty?
  end

  def match_begin_block(trimmed)
    match = trimmed.match(BEGIN_BLOCK_REGEX)
    return nil unless match

    block_kind = match[1].upcase
    return nil if block_kind != "SRC" && match[2].present?

    [ block_kind, match[2] ]
  end

  def parse_delimited_block(lines, start_idx, block_match, block_indent)
    block_kind, raw_args = block_match
    end_marker = "#+END_#{block_kind}"
    i = start_idx + 1
    total = lines.length
    block_lines = []

    while i < total && !lines[i].strip.casecmp?(end_marker)
      block_lines << (block_kind == "QUOTE" ? lines[i] : dedent_line(lines[i], block_indent))
      i += 1
    end
    i += 1 if i < total

    node =
      case block_kind
      when "SRC"
        lang = raw_args&.strip&.split&.first
        code_content = block_lines.empty? ? "" : "#{block_lines.join("\n")}\n"
        meta = lang.present? ? { "language" => lang } : nil
        InternalNode.new(type: "code_block", content: code_content, meta:)
      when "EXAMPLE"
        example_content = block_lines.empty? ? "" : "#{block_lines.join("\n")}\n"
        InternalNode.new(type: "code_block", content: example_content)
      when "QUOTE"
        InternalNode.new(type: "block_quote", children: parse_blocks(block_lines))
      end

    [ node, i ]
  end

  def dedent_line(line, max_indent)
    return line if max_indent.zero?

    removed = 0
    while removed < max_indent
      b = line.getbyte(removed)
      break unless b && b <= SPACE_BYTE

      removed += 1
    end
    removed.zero? ? line : line.byteslice(removed..)
  end

  def record_file_keyword(key, value)
    if key.casecmp?("TITLE")
      @document_title = value
    else
      @file_keywords << { "key" => key, "value" => value }
    end
  end

  def parse_table_block(lines, start_idx)
    i = start_idx
    total = lines.length
    table_lines = []

    while i < total
      trimmed, = trim_leading(lines[i])
      break unless trimmed.getbyte(0) == PIPE_BYTE

      table_lines << trimmed
      i += 1
    end

    data_rows = table_lines.reject { |l| l.rstrip.match?(TABLE_SEPARATOR_REGEX) }
    return [ nil, i ] if data_rows.empty?

    table_node = InternalNode.new(type: "table")
    data_rows.each_with_index do |row_str, r_idx|
      is_header = r_idx.zero?
      row_node = InternalNode.new(type: "table_row", meta: { "row_index" => r_idx })
      cells = row_str.rstrip.delete_prefix("|").delete_suffix("|").split("|", -1)
      cells.each_with_index do |cell_str, c_idx|
        row_node.children << InternalNode.new(
          type: "table_cell",
          meta: { "is_header" => is_header, "cell_index" => c_idx },
          children: parse_inlines(cell_str.strip)
        )
      end
      table_node.children << row_node
    end

    [ table_node, i ]
  end

  def build_paragraph_node(para_lines)
    para_node = InternalNode.new(type: "paragraph")
    last_idx = para_lines.length - 1

    para_lines.each_with_index do |p_line, idx|
      is_forced_break = p_line.match?(FORCED_LINEBREAK_REGEX)
      cleaned_line = is_forced_break ? p_line.sub(FORCED_LINEBREAK_REGEX, "") : p_line
      para_node.children.concat(parse_inlines(cleaned_line))

      if idx < last_idx
        para_node.children << InternalNode.new(type: is_forced_break ? "linebreak" : "softbreak")
      end
    end

    para_node
  end

  def block_boundary?(line, trimmed: nil, indent: nil)
    trimmed, indent = trim_leading(line) if trimmed.nil?
    first_byte = trimmed.getbyte(0)
    return false if first_byte.nil?

    case first_byte
    when STAR_BYTE
      indent.zero? ? !heading_star_count(line).nil? : !list_bullet_match(line, trimmed:, indent:).nil?
    when COLON_BYTE
      trimmed.match?(DRAWER_OPEN_REGEX)
    when HASH_BYTE
      if trimmed.start_with?("#+")
        !match_begin_block(trimmed).nil? || (!trimmed.match?(/\A#\+END_/i) && trimmed.match?(FILE_KEYWORD_REGEX))
      else
        comment_line?(trimmed)
      end
    when DASH_BYTE
      thematic_break?(trimmed) || !list_bullet_match(line, trimmed:, indent:).nil?
    when PIPE_BYTE
      true
    when PLUS_BYTE, ZERO_BYTE..NINE_BYTE
      !list_bullet_match(line, trimmed:, indent:).nil?
    else
      false
    end
  end

  def list_bullet_match(line, trimmed: nil, indent: nil)
    trimmed, indent = trim_leading(line) if trimmed.nil?
    first_byte = trimmed.getbyte(0)
    return nil if first_byte.nil?

    if first_byte == DASH_BYTE || first_byte == PLUS_BYTE || (first_byte == STAR_BYTE && indent > 0)
      second_byte = trimmed.getbyte(1)
      return nil unless second_byte == SPACE_BYTE || second_byte == TAB_BYTE

      { indent:, bullet: trimmed.getbyte(0).chr, is_ordered: false, text: trimmed.byteslice(1..).lstrip }
    elsif first_byte >= ZERO_BYTE && first_byte <= NINE_BYTE
      if (m = trimmed.match(ORDERED_LIST_REGEX))
        { indent:, bullet: m[1], is_ordered: true, text: m[2] }
      end
    end
  end

  def parse_list_block(lines, start_idx)
    first_info = list_bullet_match(lines[start_idx])
    return [ nil, start_idx + 1 ] unless first_info

    base_indent = first_info[:indent]
    is_ordered = first_info[:is_ordered]
    list_type = is_ordered ? "ordered" : "unordered"
    list_node = InternalNode.new(type: "list", meta: { "list_type" => list_type, "tight" => true })

    i = start_idx
    total = lines.length

    while i < total
      trimmed, indent = trim_leading(lines[i])

      if trimmed.empty?
        peek = next_non_blank_index(lines, i + 1)
        break if peek.nil?

        next_info = list_bullet_match(lines[peek])
        break unless next_info && next_info[:indent] == base_indent && next_info[:is_ordered] == is_ordered

        i = peek
        trimmed, indent = trim_leading(lines[i])
      end

      info = list_bullet_match(lines[i], trimmed:, indent:)
      break if info.nil? || info[:indent] < base_indent || info[:is_ordered] != is_ordered

      if info[:indent] > base_indent
        break if list_node.children.empty?

        sublist, i = parse_list_block(lines, i)
        list_node.children.last.children << sublist if sublist
        next
      end

      item_node, i = parse_list_item(lines, i + 1, base_indent:, initial_text: info[:text])
      list_node.children << item_node
    end

    [ list_node, i ]
  end

  def parse_list_item(lines, start_idx, base_indent:, initial_text:)
    item_node = InternalNode.new(type: "item")
    pending_lines = initial_text.strip.empty? ? [] : [ initial_text ]
    i = start_idx
    total = lines.length

    while i < total
      cur = lines[i]
      cur_trimmed, cur_indent = trim_leading(cur)

      if cur_trimmed.empty?
        peek = next_non_blank_index(lines, i + 1)
        break if peek.nil?

        _, next_indent = trim_leading(lines[peek])
        break if next_indent <= base_indent

        flush_list_paragraph(item_node, pending_lines)
        i = peek
        next
      end

      break if cur_indent <= base_indent

      sub_info = list_bullet_match(cur, trimmed: cur_trimmed, indent: cur_indent)
      if sub_info && sub_info[:indent] > base_indent
        flush_list_paragraph(item_node, pending_lines)
        sublist, i = parse_list_block(lines, i)
        item_node.children << sublist if sublist
        next
      end

      cur_first = cur_trimmed.getbyte(0)

      if cur_first == HASH_BYTE && cur_trimmed.start_with?("#+") && (block_match = match_begin_block(cur_trimmed))
        flush_list_paragraph(item_node, pending_lines)
        node, i = parse_delimited_block(lines, i, block_match, cur_indent)
        item_node.children << node
        next
      end

      if cur_first == PIPE_BYTE
        flush_list_paragraph(item_node, pending_lines)
        table_node, i = parse_table_block(lines, i)
        item_node.children << table_node if table_node
        next
      end

      pending_lines << cur_trimmed.rstrip
      i += 1
    end

    flush_list_paragraph(item_node, pending_lines)
    [ item_node, i ]
  end

  def flush_list_paragraph(item_node, pending_lines)
    return if pending_lines.empty?

    item_node.children << build_paragraph_node(pending_lines)
    pending_lines.clear
  end

  def next_non_blank_index(lines, start_idx)
    peek = start_idx
    total = lines.length
    peek += 1 while peek < total && lines[peek].lstrip.empty?
    peek < total ? peek : nil
  end

  # --- Inline Tokenizer ---

  def parse_inlines(text)
    return [] if text.empty?

    pos = text.index(INLINE_TRIGGER_REGEX)
    # Just raw text, no markup syntax
    return [ InternalNode.new(type: "text", content: text) ] unless pos

    nodes = []
    text_start = 0

    while pos
      node, next_pos = match_inline_at(text, pos)

      if node
        nodes << InternalNode.new(type: "text", content: text[text_start...pos]) if pos > text_start
        nodes << node
        text_start = next_pos
        pos = text.index(INLINE_TRIGGER_REGEX, next_pos)
      else
        pos = text.index(INLINE_TRIGGER_REGEX, pos + 1)
      end
    end

    nodes << InternalNode.new(type: "text", content: text[text_start..]) if text_start < text.length
    nodes
  end

  def match_inline_at(text, pos)
    char = text[pos]
    if char == "["
      match_link_at(text, pos)
    else
      match_delimited_at(text, pos, char, DELIMITED_TYPES[char])
    end
  end

  def match_link_at(text, pos)
    match = text.match(LINK_ANCHORED_REGEX, pos)
    return nil unless match

    url = match[1]
    label = match[2]
    children = label.present? ? parse_inlines(label) : [ InternalNode.new(type: "text", content: url) ]
    [ InternalNode.new(type: "link", meta: { "url" => url, "title" => "" }, children:), match.end(0) ]
  end

  def match_delimited_at(text, pos, delim, node_type)
    return nil if pos + 2 >= text.length

    close_pos = find_closing_delimiter(text, pos, delim, allow_spaces: delim != "_")
    return nil unless close_pos

    inner = text[(pos + 1)...close_pos]
    node =
      if node_type == "code"
        InternalNode.new(type: "code", content: inner)
      else
        InternalNode.new(type: node_type, children: parse_inlines(inner))
      end

    [ node, close_pos + 1 ]
  end

  def find_closing_delimiter(text, open_pos, delim, allow_spaces:)
    # As markup syntax must wrap around text, so the last case would be
    # for example with bold, *c*
    search_from = open_pos + 2

    while (close_pos = text.index(delim, search_from))
      # Underline (_..._) does not allow internal whitespace
      return nil if !allow_spaces && text[(open_pos + 1)...close_pos].match?(/\s/)

      char_before = text[close_pos - 1]
      char_after = text[close_pos + 1]

      valid_before = char_before != delim && !char_before.match?(WHITESPACE_CHAR_REGEX)
      valid_after = char_after.nil? || char_after.match?(INLINE_POST_CHAR_REGEX)

      return close_pos if valid_before && valid_after

      search_from = close_pos + 1
    end

    nil
  end

  # --- Flattening to DB Attributes ---

  def flatten_node(node, parent_id:, position:)
    db_id = SecureRandom.uuid_v7
    is_block = BLOCK_LEVEL_TYPES.include?(node.type)

    attrs = {
      id: db_id,
      document_version_id: @document_version_id,
      parent_id:,
      position:,
      node_type: node.type,
      content: node.content,
      heading_level: node.heading_level,
      meta: node.meta,
      node_id: is_block ? unique_block_id : nil,
      created_at: @now,
      updated_at: @now
    }

    @flat_nodes << attrs

    node.children&.each_with_index do |child, idx|
      flatten_node(child, parent_id: db_id, position: idx)
    end
  end

  def unique_block_id
    "block-#{SecureRandom.hex(4)}"
  end
end
