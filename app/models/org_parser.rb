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

  CODE_REGEX = /(?<=\A|[\s({\x27"\[])~(?![\s~])([^\n]+?)(?<![\s~])~(?=\z|[\s)}\x27"\]:.,!?;])/
  VERBATIM_REGEX = /(?<=\A|[\s({\x27"\[])=(?![\s=])([^\n]+?)(?<![\s=])=(?=\z|[\s)}\x27"\]:.,!?;])/
  BOLD_REGEX = /(?<=\A|[\s({\x27"\[])\*(?![\s*])([^\n]+?)(?<![\s*])\*(?=\z|[\s)}\x27"\]:.,!?;])/
  ITALIC_REGEX = /(?<=\A|[\s({\x27"\[])\/(?![\s\/])([^\n]+?)(?<![\s\/])\/(?=\z|[\s)}\x27"\]:.,!?;])/
  UNDERLINE_REGEX = /(?<=\A|[\s({\x27"\[])_(?![\s_])([^\s_]+)(?<![\s_])_(?=\z|[\s)}\x27"\]:.,!?;])/
  LINK_REGEX = /\[\[([^\]]+)\](?:\[([^\]]+)\])?\]/

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
    @content.each_line do |line|
      if line =~ /\A\s*#\+(?:TODO|SEQ_TODO|TYP_TODO):\s*(.*)\z/i
        tokens = $1.split.reject { |t| t == "|" || t.start_with?("(") }
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

      if line.strip.empty?
        i += 1
        next
      end

      # 1. Drawer check
      if line =~ /\A\s*:[a-zA-Z0-9_-]+:\s*\z/
        i += 1
        while i < total && lines[i] !~ /\A\s*:END:\s*\z/i
          i += 1
        end
        i += 1 if i < total
        next
      end

      # 2. Comments and file keywords
      if line =~ /\A\s*#(\s.*)?\z/
        i += 1
        next
      end

      if line !~ /\A\s*#\+(?:BEGIN|END)_/i && (kw_match = line.match(/\A\s*#\+([a-zA-Z0-9_-]+):(.*)\z/i))
        if top_level
          key = kw_match[1]
          value = kw_match[2].strip
          if key.casecmp?("TITLE")
            @document_title = value
          else
            @file_keywords << { "key" => key, "value" => value }
          end
        end
        i += 1
        next
      end

      # 3. Code & Example blocks
      if (src_match = line.match(/\A\s*#\+BEGIN_SRC(?:\s+([^\n]+))?\s*\z/i))
        lang = src_match[1]&.strip&.split&.first
        block_indent = line[/\A\s*/].length
        i += 1
        block_lines = []
        while i < total && lines[i] !~ /\A\s*#\+END_SRC\s*\z/i
          block_lines << lines[i].sub(/\A\s{0,#{block_indent}}/, "")
          i += 1
        end
        i += 1 if i < total
        code_content = block_lines.empty? ? "" : "#{block_lines.join("\n")}\n"
        meta = lang.present? ? { "language" => lang } : nil
        nodes << InternalNode.new(type: "code_block", content: code_content, meta:)
        next
      end

      if line =~ /\A\s*#\+BEGIN_EXAMPLE\s*\z/i
        block_indent = line[/\A\s*/].length
        i += 1
        block_lines = []
        while i < total && lines[i] !~ /\A\s*#\+END_EXAMPLE\s*\z/i
          block_lines << lines[i].sub(/\A\s{0,#{block_indent}}/, "")
          i += 1
        end
        i += 1 if i < total
        example_content = block_lines.empty? ? "" : "#{block_lines.join("\n")}\n"
        nodes << InternalNode.new(type: "code_block", content: example_content)
        next
      end

      # 4. Block quote
      if line =~ /\A\s*#\+BEGIN_QUOTE\s*\z/i
        i += 1
        quote_lines = []
        while i < total && lines[i] !~ /\A\s*#\+END_QUOTE\s*\z/i
          quote_lines << lines[i]
          i += 1
        end
        i += 1 if i < total
        quote_children = parse_blocks(quote_lines)
        nodes << InternalNode.new(type: "block_quote", children: quote_children)
        next
      end

      # 5. Headings (* at column 0)
      if line =~ /\A(\*+)(?:\s+(.*)|\s*\z)/
        stars = $1
        raw_text = ($2 || "").strip
        org_level = stars.length
        heading_level = [org_level, 6].min

        meta = { "org_level" => org_level }

        if raw_text =~ /\s+:([a-zA-Z0-9_@#%]+(?::[a-zA-Z0-9_@#%]+)*):\s*\z/
          tags = $1.split(":")
          raw_text = raw_text.sub(/\s+:([a-zA-Z0-9_@#%]+(?::[a-zA-Z0-9_@#%]+)*):\s*\z/, "").strip
          meta["tags"] = tags if tags.any?
        end

        if raw_text =~ /\A([A-Z][A-Z0-9_-]*)(?:\s+(.*)|\z)/
          candidate = $1
          rest = $2 || ""
          if @todo_keywords.include?(candidate)
            meta["todo_keyword"] = candidate
            raw_text = rest.strip
          end
        end

        children = raw_text.empty? ? [] : parse_inlines(raw_text)
        nodes << InternalNode.new(type: "heading", heading_level:, meta:, children:)
        i += 1
        next
      end

      # 6. Thematic breaks (5+ dashes)
      if line =~ /\A\s*-----+\s*\z/
        nodes << InternalNode.new(type: "thematic_break")
        i += 1
        next
      end

      # 7. Tables
      if line =~ /\A\s*\|/
        table_lines = []
        while i < total && lines[i] =~ /\A\s*\|/
          table_lines << lines[i]
          i += 1
        end

        data_rows = table_lines.reject { |l| l.strip =~ /\A\|[-+ ]+\|\z/ }
        if data_rows.any?
          table_node = InternalNode.new(type: "table")
          data_rows.each_with_index do |row_str, r_idx|
            is_header = r_idx.zero?
            row_node = InternalNode.new(type: "table_row", meta: { "row_index" => r_idx })
            cells = row_str.strip.sub(/\A\|/, "").sub(/\|\z/, "").split("|", -1)
            cells.each_with_index do |cell_str, c_idx|
              cell_node = InternalNode.new(
                type: "table_cell",
                meta: { "is_header" => is_header, "cell_index" => c_idx },
                children: parse_inlines(cell_str.strip)
              )
              row_node.children << cell_node
            end
            table_node.children << row_node
          end
          nodes << table_node
        end
        next
      end

      # 8. Lists
      if list_bullet_match(line)
        list_node, i = parse_list_block(lines, i)
        nodes << list_node if list_node
        next
      end

      # 9. Paragraph
      para_lines = []
      while i < total
        cur_line = lines[i]
        break if cur_line.strip.empty?
        break if block_boundary?(cur_line)

        para_lines << cur_line
        i += 1
      end

      if para_lines.any?
        para_node = InternalNode.new(type: "paragraph")
        para_lines.each_with_index do |p_line, idx|
          is_forced_break = p_line =~ /\\{1,2}\s*\z/
          cleaned_line = is_forced_break ? p_line.sub(/\\{1,2}\s*\z/, "") : p_line
          para_node.children.concat(parse_inlines(cleaned_line))

          if idx < para_lines.length - 1
            break_type = is_forced_break ? "linebreak" : "softbreak"
            para_node.children << InternalNode.new(type: break_type)
          end
        end
        nodes << para_node
      end
    end

    nodes
  end

  def block_boundary?(line)
    return true if line =~ /\A\*+\s+/
    return true if line =~ /\A\s*:[a-zA-Z0-9_-]+:\s*\z/
    return true if line =~ /\A\s*#(\s.*)?\z/
    return true if line =~ /\A\s*#\+/i
    return true if line =~ /\A\s*-----+\s*\z/
    return true if line =~ /\A\s*\|/
    return true if list_bullet_match(line)

    false
  end

  def list_bullet_match(line)
    if (m = line.match(/\A(\s*)([-+]|\d+[.)]|\*)\s+(.*)\z/))
      indent = m[1].length
      bullet = m[2]
      text = m[3]
      return nil if bullet == "*" && indent.zero?

      is_ordered = bullet.match?(/\A\d+[.)]\z/)
      { indent:, bullet:, is_ordered:, text: }
    end
  end

  def parse_list_block(lines, start_idx)
    first_info = list_bullet_match(lines[start_idx])
    return [nil, start_idx + 1] unless first_info

    base_indent = first_info[:indent]
    list_type = first_info[:is_ordered] ? "ordered" : "unordered"
    list_node = InternalNode.new(type: "list", meta: { "list_type" => list_type, "tight" => true })

    i = start_idx
    total = lines.length

    while i < total
      line = lines[i]

      if line.strip.empty?
        peek = i + 1
        peek += 1 while peek < total && lines[peek].strip.empty?
        break if peek >= total

        next_info = list_bullet_match(lines[peek])
        if next_info && next_info[:indent] == base_indent && next_info[:is_ordered] == (list_type == "ordered")
          i = peek
          line = lines[i]
        else
          break
        end
      end

      info = list_bullet_match(line)
      break if info.nil?
      break if info[:indent] < base_indent || info[:is_ordered] != (list_type == "ordered")

      if info[:indent] > base_indent
        if list_node.children.any?
          sublist, i = parse_list_block(lines, i)
          list_node.children.last.children << sublist if sublist
          next
        else
          break
        end
      end

      i += 1
      item_node = InternalNode.new(type: "item")
      list_node.children << item_node

      initial_text = info[:text]
      pending_para_lines = initial_text.strip.empty? ? [] : [initial_text]

      flush_para = lambda do
        if pending_para_lines.any?
          para = InternalNode.new(type: "paragraph")
          pending_para_lines.each_with_index do |l, idx|
            is_break = l =~ /\\{1,2}\s*\z/
            clean_l = is_break ? l.sub(/\\{1,2}\s*\z/, "") : l
            para.children.concat(parse_inlines(clean_l))
            if idx < pending_para_lines.length - 1
              para.children << InternalNode.new(type: is_break ? "linebreak" : "softbreak")
            end
          end
          item_node.children << para
          pending_para_lines = []
        end
      end

      while i < total
        cur = lines[i]

        if cur.strip.empty?
          peek = i + 1
          peek += 1 while peek < total && lines[peek].strip.empty?
          break if peek >= total

          next_line_indent = lines[peek][/\A\s*/].length
          break if next_line_indent <= base_indent

          flush_para.call
          i = peek
          next
        end

        cur_indent = cur[/\A\s*/].length
        break if cur_indent <= base_indent

        sub_info = list_bullet_match(cur)
        if sub_info && sub_info[:indent] > base_indent
          flush_para.call
          sublist, i = parse_list_block(lines, i)
          item_node.children << sublist if sublist
          next
        end

        if (src_match = cur.match(/\A\s*#\+BEGIN_SRC(?:\s+([^\n]+))?\s*\z/i))
          lang = src_match[1]&.strip&.split&.first
          flush_para.call
          block_indent = cur[/\A\s*/].length
          i += 1
          block_lines = []
          while i < total && lines[i] !~ /\A\s*#\+END_SRC\s*\z/i
            block_lines << lines[i].sub(/\A\s{0,#{block_indent}}/, "")
            i += 1
          end
          i += 1 if i < total
          code_content = block_lines.empty? ? "" : "#{block_lines.join("\n")}\n"
          meta = lang.present? ? { "language" => lang } : nil
          item_node.children << InternalNode.new(type: "code_block", content: code_content, meta:)
          next
        end

        if cur =~ /\A\s*#\+BEGIN_EXAMPLE\s*\z/i
          flush_para.call
          block_indent = cur[/\A\s*/].length
          i += 1
          block_lines = []
          while i < total && lines[i] !~ /\A\s*#\+END_EXAMPLE\s*\z/i
            block_lines << lines[i].sub(/\A\s{0,#{block_indent}}/, "")
            i += 1
          end
          i += 1 if i < total
          example_content = block_lines.empty? ? "" : "#{block_lines.join("\n")}\n"
          item_node.children << InternalNode.new(type: "code_block", content: example_content)
          next
        end

        if cur =~ /\A\s*#\+BEGIN_QUOTE\s*\z/i
          flush_para.call
          i += 1
          quote_lines = []
          while i < total && lines[i] !~ /\A\s*#\+END_QUOTE\s*\z/i
            quote_lines << lines[i]
            i += 1
          end
          i += 1 if i < total
          quote_children = parse_blocks(quote_lines)
          item_node.children << InternalNode.new(type: "block_quote", children: quote_children)
          next
        end

        if cur =~ /\A\s*\|/
          flush_para.call
          table_lines = []
          while i < total && lines[i] =~ /\A\s*\|/
            table_lines << lines[i]
            i += 1
          end

          data_rows = table_lines.reject { |l| l.strip =~ /\A\|[-+ ]+\|\z/ }
          if data_rows.any?
            table_node = InternalNode.new(type: "table")
            data_rows.each_with_index do |row_str, r_idx|
              is_header = r_idx.zero?
              row_node = InternalNode.new(type: "table_row", meta: { "row_index" => r_idx })
              cells = row_str.strip.sub(/\A\|/, "").sub(/\|\z/, "").split("|", -1)
              cells.each_with_index do |cell_str, c_idx|
                cell_node = InternalNode.new(
                  type: "table_cell",
                  meta: { "is_header" => is_header, "cell_index" => c_idx },
                  children: parse_inlines(cell_str.strip)
                )
                row_node.children << cell_node
              end
              table_node.children << row_node
            end
            item_node.children << table_node
          end
          next
        end

        clean_text = cur.strip
        pending_para_lines << clean_text
        i += 1
      end

      flush_para.call
    end

    [list_node, i]
  end

  # --- Inline Tokenizer ---

  def parse_inlines(text)
    return [] if text.empty?

    match = text.match(LINK_REGEX)
    unless match
      return parse_code_and_verbatim(text)
    end

    pre = text[0...match.begin(0)]
    url = match[1]
    label = match[2]
    post = text[match.end(0)..]

    nodes = []
    nodes.concat(parse_inlines(pre)) unless pre.empty?
    link_children = label.present? ? parse_inlines(label) : [InternalNode.new(type: "text", content: url)]
    nodes << InternalNode.new(type: "link", meta: { "url" => url, "title" => "" }, children: link_children)
    nodes.concat(parse_inlines(post)) unless post.empty?
    normalize_text_nodes(nodes)
  end

  def parse_code_and_verbatim(text)
    return [] if text.empty?

    matches = []
    m = text.match(CODE_REGEX)
    matches << [:code, m] if m
    m = text.match(VERBATIM_REGEX)
    matches << [:code, m] if m

    if matches.empty?
      return parse_emphasis(text)
    end

    _, match = matches.min_by { |_, m| m.begin(0) }
    pre = text[0...match.begin(0)]
    body = match[1]
    post = text[match.end(0)..]

    nodes = []
    nodes.concat(parse_code_and_verbatim(pre)) unless pre.empty?
    nodes << InternalNode.new(type: "code", content: body)
    nodes.concat(parse_code_and_verbatim(post)) unless post.empty?
    normalize_text_nodes(nodes)
  end

  def parse_emphasis(text)
    return [] if text.empty?

    matches = []
    m = text.match(BOLD_REGEX)
    matches << [:strong, m] if m
    m = text.match(ITALIC_REGEX)
    matches << [:emph, m] if m
    m = text.match(UNDERLINE_REGEX)
    matches << [:underline, m] if m

    if matches.empty?
      return [InternalNode.new(type: "text", content: text)]
    end

    type, match = matches.min_by { |_, m| m.begin(0) }
    pre = text[0...match.begin(0)]
    body = match[1]
    post = text[match.end(0)..]

    nodes = []
    nodes.concat(parse_emphasis(pre)) unless pre.empty?
    nodes << InternalNode.new(type: type.to_s, children: parse_emphasis(body))
    nodes.concat(parse_emphasis(post)) unless post.empty?
    normalize_text_nodes(nodes)
  end

  def normalize_text_nodes(nodes)
    normalized = []
    nodes.each do |node|
      if node.type == "text" && normalized.last&.type == "text"
        normalized.last.content += node.content
      else
        normalized << node
      end
    end
    normalized
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
