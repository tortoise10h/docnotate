class HomeController < ApplicationController
  def index
    @query = params[:query].presence
    @recent_documents = Document.matching_title(@query).recently_opened.limit(5)
    @editor_preference = AppSetting.get("editor_application")
  end
end
