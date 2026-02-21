# frozen_string_literal: true

require_relative 'bookmarker/version'
require_relative 'bookmarker/color'
require_relative 'bookmarker/bookmark'
require_relative 'bookmarker/profile_finder'
require_relative 'bookmarker/database'
require_relative 'bookmarker/pager'
require_relative 'bookmarker/exporter'
require_relative 'bookmarker/cli'

# Extract and browse Firefox bookmarks from the terminal.
#
# Bookmarker reads Firefox's places.sqlite database and presents
# bookmarks in a paginated, searchable terminal interface.
#
# @example Quick start from Ruby
#   db = Bookmarker::Database.new(Bookmarker::ProfileFinder.new.default_database)
#   db.bookmarks.each { |bm| puts bm }
#
# @example CLI
#   $ bookmarker --search "ruby"
#   $ bookmarker --folder "toolbar" -n 10
module Bookmarker
  # Base error class for all Bookmarker errors.
  class Error < StandardError; end

  # Raised when no Firefox profile directory can be found.
  class ProfileNotFoundError < Error; end

  # Raised when places.sqlite does not exist at the expected path.
  class DatabaseNotFoundError < Error; end
end
