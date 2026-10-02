class SettingsController < ApplicationController
  def update_editor
    editor_name = params[:editor_name].presence
    AppSetting.set("editor_application", editor_name || EditorOpener::DEFAULT)
    render json: { ok: true }
  end
end
