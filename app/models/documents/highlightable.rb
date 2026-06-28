module Documents
  module Highlightable
    extend ActiveSupport::Concern

    # Returns an array of plain Hashes (one per comment) carrying only the
    # fields the client needs to re-anchor highlights. Ordered oldest-first.
    def highlight_comments
      comments
        .order(:created_at)
        .map { |c| c.slice(:id, :content, :selected_text, :start_block_id, :end_block_id,
                           :start_offset, :end_offset, :created_at) }
    end
  end
end
