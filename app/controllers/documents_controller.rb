class DocumentsController < ApplicationController
  def create
    file_path = params[:file_path]

    if file_path.blank?
      redirect_to root_path, alert: "Please provide a file path."
      return
    end

    unless File.exist?(file_path)
      redirect_to root_path, alert: "File not found: #{file_path}"
      return
    end

    content = File.read(file_path)
    file_type = Document.file_type_from_path(file_path)

    document = Document.find_or_initialize_by(file_path: file_path)
    document.assign_attributes(
      content: content,
      file_type: file_type,
      version: document.next_version
    )

    if document.save
      document.parse_ast_and_save!
      redirect_to document_path(document)
    else
      redirect_to root_path, alert: "Failed to open file: #{document.errors.full_messages.to_sentence}"
    end
  end

  def show
    @document = Document.find(params[:id])
    @root_nodes = @document.root_node_tree
  end
end
