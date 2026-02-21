# frozen_string_literal: true

require 'json'

module Bookmarker
  class Exporter
    # Exports bookmarks as a JSON array.
    #
    # Each bookmark is serialized as an object with keys: id, title,
    # url, folder, path, and date_added (ISO 8601).
    #
    # @example
    #   exporter = Exporter::Json.new(bookmarks, output: $stdout)
    #   exporter.export
    class Json < Exporter
      # Write pretty-printed JSON array to the output stream.
      def export
        output.puts ::JSON.pretty_generate(bookmarks.map { |bm| serialize(bm) })
      end

      private

      def serialize(bookmark)
        {
          id: bookmark.id,
          title: bookmark.title,
          url: bookmark.url,
          folder: bookmark.folder,
          path: bookmark.path,
          date_added: bookmark.date_added&.iso8601
        }
      end
    end
  end
end
