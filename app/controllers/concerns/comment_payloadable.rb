module CommentPayloadable
  extend ActiveSupport::Concern

  private

  def set_comment_payload
    @comment_payload = @document.comment_payload
    @archived_comments_by_version = @document.archived_comments_by_version
    @unresolved_archived_count = @document.archived_comments.where(is_resolved: false).count
  end
end
