class Comments::ResolverController < ApplicationController
  include CommentPayloadable

  before_action :set_document
  before_action :set_comment

  def update
    if @comment.document_version_id == @document.current_version_id
      render plain: "Current-version comments cannot be resolved", status: :unprocessable_entity
      return
    end

    @comment.update!(is_resolved: !@comment.is_resolved)
    set_comment_payload
  end

  private

  def set_document
    @document = Document.find(params[:document_id])
  end

  def set_comment
    @comment = @document.comments.find(params[:comment_id])
  end
end
