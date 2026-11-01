# frozen_string_literal: true

require "test_helper"

class Markdown::CalloutParserTest < ActiveSupport::TestCase
  test "parses standard github callout types with default titles" do
    %w[NOTE TIP IMPORTANT WARNING CAUTION].each do |type|
      doc = Commonmarker.parse("> [!#{type}]\n> Body text\n")
      bq = doc.first_child
      meta = Markdown::CalloutParser.parse_callout(bq)

      assert_not_nil meta
      assert_equal type.downcase, meta["type"]
      assert_equal type.capitalize, meta["title"]
      assert_equal false, meta["custom_title"]
      assert_nil meta["collapsible"]
      # AST stripped marker line and kept body
      assert_equal :paragraph, bq.first_child.type
      assert_equal "Body text", bq.first_child.first_child.string_content
    end
  end

  test "parses obsidian aliases and maps to 5 base themes" do
    alias_expectations = {
      "bug" => { theme: "caution", title: "Bug" },
      "danger" => { theme: "caution", title: "Danger" },
      "todo" => { theme: "note", title: "Todo" },
      "info" => { theme: "note", title: "Info" },
      "tldr" => { theme: "note", title: "TL;DR" },
      "hint" => { theme: "tip", title: "Hint" },
      "success" => { theme: "tip", title: "Success" },
      "faq" => { theme: "important", title: "FAQ" },
      "question" => { theme: "important", title: "Question" },
      "attention" => { theme: "warning", title: "Attention" }
    }

    alias_expectations.each do |alias_name, expected|
      doc = Commonmarker.parse("> [!#{alias_name}]\n> Body\n")
      meta = Markdown::CalloutParser.parse_callout(doc.first_child)

      assert_not_nil meta, "Expected #{alias_name} to be parsed as a callout"
      assert_equal expected[:theme], meta["type"]
      assert_equal expected[:title], meta["title"]
      assert_equal false, meta["custom_title"]
    end
  end

  test "handles custom titles" do
    doc = Commonmarker.parse("> [!NOTE] Key Architectural Decisions\n> Body\n")
    meta = Markdown::CalloutParser.parse_callout(doc.first_child)

    assert_not_nil meta
    assert_equal "note", meta["type"]
    assert_equal "Key Architectural Decisions", meta["title"]
    assert_equal true, meta["custom_title"]
  end

  test "handles collapsible collapsed fold markers [!NOTE]- and [!NOTE] -" do
    [ "> [!NOTE]- Collapsed\n> Body\n", "> [!NOTE] - Collapsed\n> Body\n" ].each do |md|
      doc = Commonmarker.parse(md)
      meta = Markdown::CalloutParser.parse_callout(doc.first_child)

      assert_not_nil meta
      assert_equal "collapsed", meta["collapsible"]
      assert_equal "Collapsed", meta["title"]
      assert_equal true, meta["custom_title"]
    end
  end

  test "handles collapsible expanded fold markers [!TIP]+ and [!TIP] +" do
    [ "> [!TIP]+ Expanded\n> Body\n", "> [!TIP] + Expanded\n> Body\n" ].each do |md|
      doc = Commonmarker.parse(md)
      meta = Markdown::CalloutParser.parse_callout(doc.first_child)

      assert_not_nil meta
      assert_equal "expanded", meta["collapsible"]
      assert_equal "Expanded", meta["title"]
      assert_equal true, meta["custom_title"]
    end
  end

  test "drops empty paragraph if callout has no body" do
    doc = Commonmarker.parse("> [!NOTE] Only Title\n")
    bq = doc.first_child
    meta = Markdown::CalloutParser.parse_callout(bq)

    assert_not_nil meta
    assert_equal "Only Title", meta["title"]
    assert_nil bq.first_child
  end

  test "returns nil for unknown types and regular blockquotes" do
    [ "> [!UNKNOWN] Title\n> Body\n", "> Regular quote\n" ].each do |md|
      doc = Commonmarker.parse(md)
      bq = doc.first_child
      meta = Markdown::CalloutParser.parse_callout(bq)

      assert_nil meta
      assert_not_nil bq.first_child # AST untouched
    end
  end

  test "render_callouts_in_html transforms html blockquotes" do
    html = "<blockquote><p>[!NOTE] Custom Title<br />Safe body</p></blockquote>"
    rendered = Markdown::CalloutParser.render_callouts_in_html(html)

    assert_includes rendered, '<div class="callout callout--note">'
    assert_includes rendered, '<span class="callout__title">Custom Title</span>'
    assert_includes rendered, '<div class="callout__content"><p>Safe body</p></div>'
  end

  test "render_callouts_in_html handles collapsible callouts" do
    html = "<blockquote><p>[!TIP]- Collapsed tip<br />Details</p></blockquote>"
    rendered = Markdown::CalloutParser.render_callouts_in_html(html)

    assert_includes rendered, '<details class="callout callout--tip callout--collapsible">'
    assert_includes rendered, '<summary class="callout__header">'
    assert_includes rendered, '<span class="callout__fold-icon"'
    assert_includes rendered, '<span class="callout__title">Collapsed tip</span>'
  end
end
