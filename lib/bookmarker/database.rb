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
  # Uses a recursive CTE to resolve the full folder path for each bookmark.
  # See doc/adr/0005-recursive-cte-for-full-bookmark-path.md for rationale.
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
    # Recursive CTE that walks the moz_bookmarks parent chain to build
    # the full folder path for each bookmark. Each bookmark gets a
    # pipe-delimited path string (e.g. "menu|toolbar|subfolder") that
    # is split into an array in Ruby.
    QUERY = <<~SQL
      WITH RECURSIVE ancestry(bid, aid, path, d) AS (
        SELECT id, parent, CAST('' AS TEXT), 0
        FROM moz_bookmarks
        WHERE type = 1
        UNION ALL
        SELECT ancestry.bid, mb.parent,
          CASE WHEN ancestry.path = ''
               THEN COALESCE(mb.title, '')
               ELSE COALESCE(mb.title, '') || '|' || ancestry.path
          END,
          ancestry.d + 1
        FROM ancestry
        JOIN moz_bookmarks mb ON mb.id = ancestry.aid
        WHERE mb.parent <> 0
      )
      SELECT a.bid AS id, b.title, p.url, a.path AS folder_path, b.dateAdded
      FROM ancestry a
      JOIN moz_bookmarks b ON a.bid = b.id
      JOIN moz_places p ON b.fk = p.id
      WHERE p.url NOT LIKE 'place:%'
        AND a.d = (SELECT MAX(a2.d) FROM ancestry a2 WHERE a2.bid = a.bid)
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

    # Case-insensitive search across title, URL, and full path.
    #
    # @param term [String] search term
    # @return [Array<Bookmark>] matching bookmarks
    def search(term)
      pattern = term.downcase
      bookmarks.select do |bm|
        (bm.title&.downcase&.include?(pattern)) ||
          bm.url.downcase.include?(pattern) ||
          bm.full_path.downcase.include?(pattern)
      end
    end

    # @return [Array<String>] sorted unique folder names (immediate parent)
    def folders
      bookmarks.filter_map(&:folder).uniq.sort
    end

    # Filters bookmarks by folder name, matching against any level
    # of the path hierarchy.
    #
    # @param folder_name [String] folder name to match at any level
    # @return [Array<Bookmark>] bookmarks with that folder in their path
    def by_folder(folder_name)
      bookmarks.select do |bm|
        bm.folder == folder_name ||
          (bm.path&.include?(folder_name))
      end
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
      path_parts = parse_path(row["folder_path"])
      Bookmark.new(
        id: row["id"],
        title: row["title"],
        url: row["url"],
        folder: path_parts&.last,
        path: path_parts,
        date_added: parse_timestamp(row["dateAdded"])
      )
    end

    # Splits the pipe-delimited path string from the CTE, filtering
    # out the root node (empty title) and the synthetic "root" entries.
    #
    # @param path_str [String, nil] pipe-delimited path
    # @return [Array<String>, nil] path segments from root to parent
    def parse_path(path_str)
      return nil if path_str.nil? || path_str.empty?

      parts = path_str.split("|").reject(&:empty?)
      parts.empty? ? nil : parts
    end

    # Firefox stores timestamps as microseconds since Unix epoch.
    def parse_timestamp(microseconds)
      return nil unless microseconds

      Time.at(microseconds / 1_000_000)
    end
  end
end
