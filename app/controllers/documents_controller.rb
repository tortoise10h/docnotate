class DocumentsController < ApplicationController
  def open
    file_path = resolve_file_path

    if file_path.nil?
      redirect_to root_path, alert: "No file provided"
      return
    end

    document = Document.open(file_path)

    if document&.persisted?
      redirect_to document_path(document)
    else
      redirect_to root_path, alert: "Failed to open file"
    end
  end

  def show
    @document = Document.find(params[:id])
    @root_nodes = @document.root_node_tree
  end

  private

  def resolve_file_path
    # Paste file_path directly to the input form
    if params[:file_path].present?
      params[:file_path]
    # Choose file from file picker, web file picker hide the real path from us so this path here is just a temp path
    elsif params[:file].present?
      params[:file].path
    end
  end
end
