# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
  enable_coverage :branch
  minimum_coverage line: 95, branch: 90
end

require 'bookmarker'
require 'tmpdir'
require 'fileutils'

module TestHelpers
  def create_test_database(bookmarks: default_bookmarks, extra_folders: [])
    dir = Dir.mktmpdir('bookmarker_test')
    db_path = File.join(dir, 'places.sqlite')
    db = SQLite3::Database.new(db_path)

    db.execute <<~SQL
      CREATE TABLE moz_places (
        id INTEGER PRIMARY KEY,
        url LONGVARCHAR,
        title LONGVARCHAR,
        rev_host LONGVARCHAR,
        visit_count INTEGER DEFAULT 0,
        hidden INTEGER DEFAULT 0 NOT NULL,
        typed INTEGER DEFAULT 0 NOT NULL,
        frecency INTEGER DEFAULT -1 NOT NULL,
        last_visit_date INTEGER,
        guid TEXT,
        foreign_count INTEGER DEFAULT 0 NOT NULL,
        url_hash INTEGER DEFAULT 0 NOT NULL
      )
    SQL

    db.execute <<~SQL
      CREATE TABLE moz_bookmarks (
        id INTEGER PRIMARY KEY,
        type INTEGER,
        fk INTEGER DEFAULT NULL,
        parent INTEGER,
        position INTEGER,
        title LONGVARCHAR,
        keyword_id INTEGER,
        folder_type TEXT,
        dateAdded INTEGER,
        lastModified INTEGER,
        guid TEXT,
        syncStatus INTEGER NOT NULL DEFAULT 0,
        syncChangeCounter INTEGER NOT NULL DEFAULT 1
      )
    SQL

    # Create root and folder bookmarks
    db.execute "INSERT INTO moz_bookmarks (id, type, parent, position, title) VALUES (1, 2, 0, 0, 'root')"
    db.execute "INSERT INTO moz_bookmarks (id, type, parent, position, title) VALUES (2, 2, 1, 0, 'menu')"
    db.execute "INSERT INTO moz_bookmarks (id, type, parent, position, title) VALUES (3, 2, 1, 1, 'toolbar')"

    # Insert any extra folders (for testing nested paths)
    extra_folders.each do |folder|
      db.execute(
        'INSERT INTO moz_bookmarks (id, type, parent, position, title) VALUES (?, 2, ?, ?, ?)',
        [folder[:id], folder[:parent], folder[:position] || 0, folder[:title]]
      )
    end

    bookmarks.each_with_index do |bm, i|
      place_id = i + 1
      bookmark_id = i + 100
      db.execute(
        'INSERT INTO moz_places (id, url, title) VALUES (?, ?, ?)',
        [place_id, bm[:url], bm[:title]]
      )
      date = bm.key?(:date_added) ? bm[:date_added] : (1_700_000_000_000_000 - (i * 1_000_000))
      db.execute(
        'INSERT INTO moz_bookmarks (id, type, fk, parent, position, title, dateAdded) VALUES (?, 1, ?, ?, ?, ?, ?)',
        [bookmark_id, place_id, bm[:parent] || 2, i, bm[:title], date]
      )
    end

    db.close
    [dir, db_path]
  end

  def default_bookmarks
    (1..30).map do |i|
      { title: "Bookmark #{i}", url: "https://example.com/#{i}", parent: i <= 15 ? 2 : 3 }
    end
  end

  def cleanup_test_dir(dir)
    FileUtils.rm_rf(dir)
  end
end

RSpec.configure do |config|
  config.include TestHelpers

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand config.seed
end
