class CommentsController < ApplicationController
  def create
    document = Document.find(params[:document_id])
    comment = document.comments.build(comment_params)

    if comment.save
      redirect_to open_documents_path(file_path: document.file_path), notice: "Comment added."
    else
      redirect_to open_documents_path(file_path: document.file_path), alert: comment.errors.full_messages.to_sentence
    end
  end

  private

  def comment_params
    params.permit(
      :content,
      :start_block_id,
      :end_block_id,
      :start_offset,
      :end_offset,
      :selected_text,
      :prefix_text,
      :postfix_text
    )
  end
end
