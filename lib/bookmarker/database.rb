# frozen_string_literal: true

require "sqlite3"
require "fileutils"
require "tempfile"

module Bookmarker
  # Reads Firefox bookmarks from a places.sqlite database.
  #
  # To avoid SQLite locking conflicts with a running Firefox process,
  # the database is copied to a temporary file before reading.
  # See doc/adr/0001-copy-sqlite-to-tempfile.md for rationale.
  #
  # Bookmarks are loaded lazily on first access and cached for the
  # lifetime of the Database instance.
  #
  # @example
  #   db = Database.new("/path/to/places.sqlite")
  #   db.count                    # => 326
  #   db.search("ruby")           # => [Bookmark, ...]
  #   db.folders                  # => ["menu", "toolbar", ...]
  #   db.by_folder("toolbar")     # => [Bookmark, ...]
  class Database
    # SQL query joining moz_bookmarks to moz_places and resolving
    # the parent folder name. Excludes Firefox internal place: URIs.
    QUERY = <<~SQL
      SELECT b.id, b.title, p.url, parent_b.title AS folder, b.dateAdded
      FROM moz_bookmarks b
      JOIN moz_places p ON b.fk = p.id
      LEFT JOIN moz_bookmarks parent_b ON b.parent = parent_b.id
      WHERE b.type = 1
        AND p.url IS NOT NULL
        AND p.url NOT LIKE 'place:%'
      ORDER BY b.dateAdded DESC
    SQL

    # @return [String] path to the source places.sqlite file
    attr_reader :db_path

    # @param db_path [String] absolute path to a Firefox places.sqlite
    # @raise [DatabaseNotFoundError] if the file does not exist
    def initialize(db_path)
      @db_path = db_path
      validate!
    end

    # @return [Array<Bookmark>] all bookmarks, newest first (cached)
    def bookmarks
      @bookmarks ||= fetch_bookmarks
    end

    # @return [Integer] total number of bookmarks
    def count
      bookmarks.size
    end

    # Case-insensitive search across title, URL, and folder name.
    #
    # @param term [String] search term
    # @return [Array<Bookmark>] matching bookmarks
    def search(term)
      pattern = term.downcase
      bookmarks.select do |bm|
        (bm.title&.downcase&.include?(pattern)) ||
          bm.url.downcase.include?(pattern) ||
          (bm.folder&.downcase&.include?(pattern))
      end
    end

    # @return [Array<String>] sorted unique folder names
    def folders
      bookmarks.filter_map(&:folder).uniq.sort
    end

    # @param folder_name [String] exact folder name to match
    # @return [Array<Bookmark>] bookmarks in that folder
    def by_folder(folder_name)
      bookmarks.select { |bm| bm.folder == folder_name }
    end

    private

    def validate!
      raise DatabaseNotFoundError, "Database not found: #{@db_path}" unless File.exist?(@db_path)
    end

    def fetch_bookmarks
      working_copy = create_working_copy
      db = SQLite3::Database.new(working_copy)
      db.results_as_hash = true
      rows = db.execute(QUERY)
      rows.map { |row| row_to_bookmark(row) }
    ensure
      db&.close
      File.delete(working_copy) if working_copy && File.exist?(working_copy)
    end

    def create_working_copy
      tmp = Tempfile.new(["bookmarker", ".sqlite"])
      tmp_path = tmp.path
      tmp.close
      FileUtils.cp(@db_path, tmp_path)
      tmp_path
    end

    def row_to_bookmark(row)
      Bookmark.new(
        id: row["id"],
        title: row["title"],
        url: row["url"],
        folder: row["folder"],
        date_added: parse_timestamp(row["dateAdded"])
      )
    end

    # Firefox stores timestamps as microseconds since Unix epoch.
    def parse_timestamp(microseconds)
      return nil unless microseconds

      Time.at(microseconds / 1_000_000)
    end
  end
end
