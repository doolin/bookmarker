# frozen_string_literal: true

module Bookmarker
  # Locates Firefox profile directories and their places.sqlite databases
  # across macOS, Linux, and Windows.
  #
  # Firefox stores bookmarks in a SQLite database called places.sqlite
  # inside each profile directory. A user may have multiple profiles;
  # this class finds all of them and picks the most likely default.
  #
  # @example
  #   finder = ProfileFinder.new
  #   finder.find_databases   # => ["/Users/me/.../abc.default-release/places.sqlite"]
  #   finder.default_database # => "/Users/me/.../abc.default-release/places.sqlite"
  class ProfileFinder
    # Platform-specific Firefox profile root directories.
    FIREFOX_DIRS = {
      'darwin' => File.join(Dir.home, 'Library', 'Application Support', 'Firefox', 'Profiles'),
      'linux' => File.join(Dir.home, '.mozilla', 'firefox'),
      'windows' => File.join(ENV.fetch('APPDATA', ''), 'Mozilla', 'Firefox', 'Profiles')
    }.freeze

    # The SQLite database filename Firefox uses for bookmarks and history.
    DB_NAME = 'places.sqlite'

    # @param platform [String] override platform detection ("darwin", "linux", "windows")
    def initialize(platform: detect_platform)
      @platform = platform
    end

    # @return [String] absolute path to the Firefox profiles directory
    # @raise [Error] if the platform is unsupported
    def profiles_dir
      FIREFOX_DIRS[@platform] || raise(Error, "Unsupported platform: #{@platform}")
    end

    # @return [Array<String>] sorted list of places.sqlite paths found
    def find_databases
      dir = profiles_dir
      return [] unless Dir.exist?(dir)

      Dir.glob(File.join(dir, '*', DB_NAME))
    end

    # Returns the most likely default database, preferring the
    # "default-release" profile that Firefox creates on first run.
    #
    # @return [String] path to the default places.sqlite
    # @raise [DatabaseNotFoundError] if no databases are found
    def default_database
      dbs = find_databases
      raise DatabaseNotFoundError, "No Firefox places.sqlite found in #{profiles_dir}" if dbs.empty?

      dbs.find { |path| path.include?('default-release') } || dbs.first
    end

    private

    def detect_platform
      case RbConfig::CONFIG['host_os']
      when /darwin/i then 'darwin'
      when /linux/i then 'linux'
      when /mswin|mingw|cygwin/i then 'windows'
      else 'unknown'
      end
    end
  end
end
