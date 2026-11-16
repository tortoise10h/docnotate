class ApplicationController < ActionController::Base
  include Pagy::Backend

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :theme_preference, :palette_recent_documents

  def theme_preference
    cookies[:theme].presence_in(AppSetting::THEMES) || AppSetting.theme
  end

  def palette_recent_documents
    @palette_recent_documents ||= Document.recently_opened
      .select(:id, :name, :file_path, :file_type, :last_opened_at)
      .limit(10)
  end
end
