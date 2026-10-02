class EditorOpener
  DEFAULT = "default"

  def initialize(application:)
    @application = application
  end

  def open(file_path)
    if @application.blank? || @application == DEFAULT
      open_with_default(file_path)
    else
      open_with_application(file_path, @application)
    end
  end

  private

  def open_with_default(file_path)
    case host_os
    when :macos then system("open", file_path)
    when :linux then system("xdg-open", file_path)
    when :windows then system("cmd", "/c", "start", "", file_path)
    else false
    end
  end

  def open_with_application(file_path, application)
    case host_os
    when :macos then system("open", "-a", application, file_path)
    when :windows then system("cmd", "/c", "start", "", application, file_path)
    else open_with_default(file_path)
    end
  end

  def host_os
    case RUBY_PLATFORM
    when /darwin/ then :macos
    when /linux/ then :linux
    when /mswin|mingw|cygwin/ then :windows
    else :unknown
    end
  end
end
