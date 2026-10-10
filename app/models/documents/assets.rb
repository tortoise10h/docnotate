module Documents
  module Assets
    extend ActiveSupport::Concern

    # Documents themselves are excluded, so a sibling .html never gets served from the app origin.
    SERVABLE_EXTENSIONS = %w[.css .js .png .jpg .jpeg .gif .webp .avif .svg .ico .woff .woff2 .ttf .otf .mp4 .webm .mp3 .wav .ogg].freeze

    def asset_file(relative_path)
      return if File.basename(relative_path).start_with?(".")
      return unless SERVABLE_EXTENSIONS.include?(File.extname(relative_path).downcase)

      directory = File.realpath(File.dirname(file_path))
      candidate = File.expand_path(relative_path, directory)
      return unless File.file?(candidate)

      real_path = File.realpath(candidate)
      real_path if real_path.start_with?(File.join(directory, ""))
    end
  end
end
