# frozen_string_literal: true

module Bookmarker
  # Immutable value object representing a single Firefox bookmark.
  #
  # Built on Ruby's Data.define for structural equality and
  # pattern matching support.
  #
  # @example
  #   bm = Bookmark.new(id: 1, title: "Example", url: "https://example.com",
  #                     folder: "toolbar", path: ["menu", "toolbar"],
  #                     date_added: Time.now)
  #   puts bm              # => "Example\n  https://example.com"
  #   puts bm.formatted(3) # => "3. Example\n   [menu > toolbar]\n   https://example.com"
  #   puts bm.full_path    # => "menu > toolbar"
  Bookmark = Data.define(:id, :title, :url, :folder, :path, :date_added) do
    # @return [String] title and URL on two lines, suitable for plain output
    def to_s
      "#{title || '(untitled)'}\n  #{url}"
    end

    # @param index [Integer] display position number
    # @return [String] numbered title, path, and indented URL for paged output
    def formatted(index)
      display_title = title || '(untitled)'
      lines = ["#{index}. #{display_title}"]
      lines << "   [#{full_path}]" if path && path.size > 1
      lines << "   #{url}"
      lines.join("\n")
    end

    # @return [String] folder hierarchy joined with " > ", or the folder name
    def full_path
      return folder || '' unless path && !path.empty?

      path.join(' > ')
    end
  end
end
