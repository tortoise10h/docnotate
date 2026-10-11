module Documents
  module Commentable
    extend ActiveSupport::Concern

    # Latest inline comments, show on document highlight
    def highlight_comments
      current_version_comments
        .order(:created_at)
        .map { |c| c.slice(:id, :content, :selected_text, :start_block_id, :end_block_id,
                           :start_offset, :end_offset, :is_resolved, :created_at) }
    end

    # Comments belong to previous document version, show on a separate section as archived comments
    def archived_comments
      comments
        .where.not(document_version_id: current_version_id)
        .joins(:document_version)
        .merge(DocumentVersion.order(created_at: :desc))
        .order("comments.created_at ASC")
    end

    # Group archived comments by their document version, preserving version order
    def archived_comments_by_version
      archived_comments.group_by(&:document_version)
    end

    # Serialized payload for archived comments used by the "Previous comments"
    # section and the comment source JSON.
    def archived_comments_payload
      archived_comments.map do |comment|
        comment.slice(:id, :content, :selected_text, :created_at, :is_resolved)
               .merge(version: comment.document_version.version)
      end
    end

    # Full comment source consumed by Stimulus: current inline highlights
    # plus archived comments for the inbox / previous-comments section.
    def comment_payload
      {
        current: highlight_comments,
        archived: archived_comments_payload
      }
    end

    # comment_payload filtered by resolution state, for agent surfaces that
    # want only the feedback still open. Shapes stay identical to the UI's so
    # both surfaces read the same contract.
    def comments_payload(status: "all")
      payload = comment_payload
      return payload if status == "all"

      resolved = status == "resolved"
      payload.transform_values { |list| list.select { |comment| comment[:is_resolved] == resolved } }
    end

    private

    def current_version_comments
      return Comment.none if current_version_id.blank?

      comments.where(document_version_id: current_version_id)
    end
  end
end
