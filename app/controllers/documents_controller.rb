class DocumentsController < ApplicationController
  before_action :set_document, only: %i[update destroy]

  def index
    @pagy, @documents = pagy(Document.order(last_opened_at: :desc))
  end

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

  def update
    if @document.update(document_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to documents_path, notice: "File renamed" }
      end
    else
      respond_to do |format|
        format.turbo_stream { render :update, status: :unprocessable_entity }
        format.html { redirect_to documents_path, alert: "Unable to rename file" }
      end
    end
  end

  def destroy
    @document.destroy!
    @documents_count = Document.count
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to documents_path, notice: "Removed from history" }
    end
  rescue ActiveRecord::RecordNotDestroyed
    respond_to do |format|
      format.turbo_stream { head :unprocessable_entity }
      format.html { redirect_to documents_path, alert: "Unable to remove file from history" }
    end
  end

  private

  def set_document
    @document = Document.find(params[:id])
  end

  def document_params
    params.require(:document).permit(:name)
  end

  def resolve_file_path
    params[:file_path]
  end

  def prepare_document
    @document.touch_last_opened!
    @root_nodes = @document.root_node_tree
    @comment_payload = @document.comment_payload
    @archived_comments_by_version = @document.archived_comments_by_version
    @unresolved_archived_count = @document.archived_comments.where(is_resolved: false).count
  end
end
