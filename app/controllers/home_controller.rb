class HomeController < ApplicationController
  def index
    @recent_documents = Document.recently_opened.limit(5)
    @editor_preference = AppSetting.get("editor_application")
  end
end
