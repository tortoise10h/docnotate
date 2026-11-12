# frozen_string_literal: true

require "test_helper"

class OrgDocumentsTest < ActionDispatch::IntegrationTest
  include DocumentsHelper

  test "opens an org document, persisting version, nodes, outline, and table of contents" do
    file = Tempfile.new([ "task-list", ".org" ])
    file.write(<<~ORG)
      #+TITLE: Team Tasks
      #+TODO: TODO WORKING | DONE
      * TODO Design architecture :design:v1:
      This is the overview paragraph with *bold* and /italic/ text.

      ** WORKING Implement parser
      - Feature 1
        - Subfeature 1.1
      - Feature 2

      *** DONE Ship v1
      #+BEGIN_SRC ruby
      puts "hello from org"
      #+END_SRC

      #+BEGIN_QUOTE
      A wise quote.
      #+END_QUOTE

      | Task | Assignee |
      |------+----------|
      | Code | Ada      |
    ORG
    file.close

    get open_documents_path, params: { file_path: file.path }

    assert_response :success
    document = Document.find_by!(file_path: File.realpath(file.path))
    assert_equal "org", document.file_type
    assert document.org?
    assert document.persisted?

    # Verify version and nodes
    version = document.current_version
    assert_equal "v1", version.version
    assert_operator version.document_nodes.count, :>, 10

    # Verify table of contents: only headings with levels 1..3, clean text
    toc = document.table_of_contents
    assert_equal 3, toc.size
    assert_equal [1, 2, 3], toc.map(&:level)
    assert_equal ["Design architecture", "Implement parser", "Ship v1"], toc.map(&:text)

    # Verify content outline has commentable block IDs and clean text
    outline = document.content_outline
    outline_types = outline.map { |e| e[:type] }
    assert_includes outline_types, "heading"
    assert_includes outline_types, "paragraph"
    assert_includes outline_types, "list"
    assert_includes outline_types, "code_block"
    assert_includes outline_types, "block_quote"
    assert_includes outline_types, "table"

    first_heading = outline.find { |e| e[:type] == "heading" }
    assert_equal "Design architecture", first_heading[:text]
    assert first_heading[:block_id].start_with?("block-")

    # Verify UI rendering: TODO badges, tags, code blocks, quote, table
    assert_select ".document-node--org-todo", text: "TODO"
    assert_select ".document-node--org-todo--working", text: "WORKING"
    assert_select ".document-node--org-todo--done", text: "DONE"
    assert_select ".document-node--org-tag", text: ":design:"
    assert_select ".document-node--org-tag", text: ":v1:"
    assert_select "pre.document-node--code-block code.language-ruby", text: /hello from org/
    assert_select "blockquote.document-node--blockquote", text: /A wise quote/
    assert_select "table.document-node--table th", text: "Task"
    assert_select "table.document-node--table td", text: "Ada"

    # Editing scope: web editor and edit button are not present for .org files
    assert_select ".document__markdown-editor", count: 0
    assert_select "[data-action='click->markdown-editor#edit']", count: 0
  ensure
    file&.unlink
  end

  test "regression: markdown blockquote renders blockquote tag and anchor id" do
    file = Tempfile.new([ "quote", ".md" ])
    file.write("> A markdown blockquote.\n")
    file.close

    get open_documents_path, params: { file_path: file.path }

    assert_response :success
    document = Document.find_by!(file_path: File.realpath(file.path))
    assert document.markdown?

    assert_select "blockquote.document-node--blockquote[id^='block-']", text: /A markdown blockquote/
  ensure
    file&.unlink
  end

  test "filter documents by org file type" do
    file = Tempfile.new([ "filter-test", ".org" ])
    file.write("* Header\nContent\n")
    file.close

    get open_documents_path, params: { file_path: file.path }
    assert_response :success

    get documents_path, params: { file_type: "org" }
    assert_response :success
    assert_select ".file-badge--org", text: "org"
  ensure
    file&.unlink
  end
end
