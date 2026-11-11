module Documents
  class MarkdownFilesController < ApplicationController
    before_action :set_document

    def update
      content = params.require(:document).permit(:content)[:content]
      @document.save_markdown_file!(content)

      redirect_to open_documents_path(file_path: @document.file_path), status: :see_other
    rescue ActionController::ParameterMissing, ArgumentError, ActiveRecord::RecordInvalid, Errno::EACCES, Errno::ENOENT => e
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "markdown_editor_error",
            helpers.tag.div(e.message, class: "document__markdown-editor-error", id: "markdown_editor_error", data: { markdown_editor_target: "error" })
          ), status: :unprocessable_entity
        end
        format.html do
          render plain: e.message, status: :unprocessable_entity
        end
        format.json do
          render json: { error: e.message }, status: :unprocessable_entity
        end
      end
    end

    private

    def set_document
      @document = Document.find(params[:document_id])
    end
  end
end
