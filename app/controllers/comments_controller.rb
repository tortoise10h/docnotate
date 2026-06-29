class CommentsController < ApplicationController
  def create
    document = Document.find(params[:document_id])
    comment = document.comments.build(comment_params)

    if comment.save
      @comment_payload = document.highlight_comments
      respond_to { |format| format.turbo_stream }
    else
      @create_error = comment.errors.full_messages.to_sentence
      @comment_payload = document.highlight_comments
      respond_to do |format|
        format.turbo_stream { render :create, status: :unprocessable_entity }
      end
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
