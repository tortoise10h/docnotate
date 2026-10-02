class Comments::VersionResolverController < ApplicationController
  include CommentPayloadable

  before_action :set_document
  before_action :set_document_version

  def update
    if @document_version.id == @document.current_version_id
      render plain: "Current-version comments cannot be resolved", status: :unprocessable_entity
      return
    end

    @document_version.resolve_all_comments!(resolved?)
    set_comment_payload
  end

  private

  def set_document
    @document = Document.find(params[:document_id])
  end

  def set_document_version
    @document_version = @document.document_versions.find(params[:document_version_id])
  end

  def resolved?
    ActiveModel::Type::Boolean.new.cast(params[:resolved])
  end
end