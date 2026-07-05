module CommentPayloadable
  extend ActiveSupport::Concern

  private

  def set_comment_payload
    @comment_payload = @document.comment_payload
    @archived_comments = @document.archived_comments
    @unresolved_archived_count = @archived_comments.where(is_resolved: false).count
  end
end
