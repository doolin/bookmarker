# frozen_string_literal: true

module Bookmarker
  # Immutable value object representing a single Firefox bookmark.
  #
  # Built on Ruby's Data.define for structural equality and
  # pattern matching support.
  #
  # @example
  #   bm = Bookmark.new(id: 1, title: "Example", url: "https://example.com",
  #                     folder: "toolbar", date_added: Time.now)
  #   puts bm           # => "Example\n  https://example.com"
  #   puts bm.formatted(3) # => "3. Example\n   https://example.com"
  Bookmark = Data.define(:id, :title, :url, :folder, :date_added) do
    # @return [String] title and URL on two lines, suitable for plain output
    def to_s
      "#{title || "(untitled)"}\n  #{url}"
    end

    # @param index [Integer] display position number
    # @return [String] numbered title and indented URL for paged output
    def formatted(index)
      display_title = title || "(untitled)"
      "#{index}. #{display_title}\n   #{url}"
    end
  end
end
