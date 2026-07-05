class DocumentsController < ApplicationController
  def open
    file_path = resolve_file_path

    if file_path.blank?
      redirect_to root_path, alert: "No file provided"
      return
    end

    unless Document.markdown_file?(file_path)
      @file_path = file_path
      render :unsupported_file, status: :unsupported_media_type
      return
    end

    @document = Document.open(file_path)

    unless @document.persisted?
      redirect_to root_path, alert: "Failed to open file"
      return
    end

    prepare_document
    render :show
  rescue ArgumentError, Errno::ENOENT, Errno::EACCES
    redirect_to root_path, alert: "File not found"
  end

  def show
    @document = Document.find(params[:id])
    redirect_to open_documents_path(file_path: @document.file_path)
  end

  private

  def resolve_file_path
    params[:file_path]
  end

  def prepare_document
    @document.touch_last_opened!
    @root_nodes = @document.root_node_tree
    @comment_payload = @document.comment_payload
    @archived_comments = @document.archived_comments
    @unresolved_archived_count = @archived_comments.where(is_resolved: false).count
  end
end
