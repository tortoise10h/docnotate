class HomeController < ApplicationController
  def index
    @recent_documents = Document.where.not(last_opened_at: nil)
                                 .order(last_opened_at: :desc)
                                 .limit(5)
  end
end
