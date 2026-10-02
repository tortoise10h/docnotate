class HomeController < ApplicationController
  def index
    @recent_documents = Document.recently_opened.limit(5)
  end
end
