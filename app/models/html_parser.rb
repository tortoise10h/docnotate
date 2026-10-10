class HtmlParser
  BLOCK_TAGS = %w[p h1 h2 h3 h4 h5 h6 li blockquote pre table tr td th hr img
                  section dd dt dl figcaption figure main nav aside article header footer ul ol div].freeze

  # Inline elements only become blocks when no block ancestor exists, so text
  # wrapped in <span>/<em>/<a> inside a paragraph stays part of that paragraph.
  INLINE_TAGS = %w[a abbr b bdi bdo button cite code data del dfn em i ins kbd label
                   mark q s samp small span strong sub sup time u var].freeze

  # svg/math text would otherwise become blocks whose <mark> highlights render oddly
  SKIPPED_TAGS = %w[script style noscript template svg math].freeze

  HEADING_TAGS = %w[h1 h2 h3 h4 h5 h6].freeze

  attr_reader :annotated_html

  def initialize(document_version_id:, content:)
    @document_version_id = document_version_id
    @content = content
  end

  def parse
    document = Nokogiri::HTML5.parse(@content)
    @nodes = []
    @child_counts = Hash.new(0)
    @used_block_ids = Set.new

    walk(document.at("body"), parent_id: nil, inside_block: false)

    @annotated_html = document.to_html
    @nodes
  end

  private

  def walk(element, parent_id:, inside_block:)
    element.element_children.each do |child|
      next if SKIPPED_TAGS.include?(child.name)

      if block?(child, inside_block:)
        register_block(child, parent_id:)
      else
        walk(child, parent_id:, inside_block:)
      end
    end
  end

  def register_block(element, parent_id:)
    db_id = SecureRandom.uuid_v7
    node_id = unique_block_id
    element["data-docnotate-block"] = node_id
    now = Time.current

    attrs = {
      id: db_id,
      document_version_id: @document_version_id,
      parent_id:,
      position: next_position(parent_id),
      node_type: node_type_for(element),
      content: nil,
      heading_level: heading_level_for(element),
      meta: nil,
      node_id:,
      created_at: now,
      updated_at: now
    }
    @nodes << attrs

    walk(element, parent_id: db_id, inside_block: true)

    attrs[:content] = block_text(element).presence unless @child_counts.key?(db_id)
  end

  def block?(element, inside_block:)
    return true if BLOCK_TAGS.include?(element.name)
    return false unless direct_text?(element)

    !INLINE_TAGS.include?(element.name) || !inside_block
  end

  def direct_text?(element)
    element.children.any? { |child| child.text? && child.content.match?(/\S/) }
  end

  def node_type_for(element)
    HEADING_TAGS.include?(element.name) ? "heading" : element.name
  end

  def heading_level_for(element)
    return nil unless HEADING_TAGS.include?(element.name)

    element.name.delete_prefix("h").to_i
  end

  def block_text(element)
    text = element.xpath(".//text()[not(ancestor::*[#{SKIPPED_TAGS.map { |tag| "self::#{tag}" }.join(' or ')}])]")
    text.map(&:content).join.gsub(/\s+/, " ").strip
  end

  def next_position(parent_id)
    position = @child_counts[parent_id]
    @child_counts[parent_id] += 1
    position
  end

  def unique_block_id
    loop do
      id = "block-#{SecureRandom.hex(4)}"
      return id if @used_block_ids.add?(id)
    end
  end
end
