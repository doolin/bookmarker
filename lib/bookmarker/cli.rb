# frozen_string_literal: true

require_relative 'cli/option_parser'

module Bookmarker
  # Command-line interface for browsing Firefox bookmarks.
  #
  # All IO streams are injectable for testability. The #run method
  # returns an exit code (0 for success, 1 for errors).
  #
  # @example
  #   exit Bookmarker::CLI.new.run
  #
  # @example Testing
  #   out = StringIO.new
  #   cli = Bookmarker::CLI.new(argv: ["--count"], stdout: out, stdin: StringIO.new)
  #   cli.run  # => 0
  #   out.string # => "Total bookmarks: 326\n"
  class CLI
    # @return [Array<String>] command-line arguments
    # @return [IO] stdout stream
    # @return [IO] stderr stream
    # @return [IO] stdin stream
    attr_reader :argv, :stdout, :stderr, :stdin

    # @param argv [Array<String>] command-line arguments (default ARGV)
    # @param stdout [IO] output stream (default $stdout)
    # @param stderr [IO] error stream (default $stderr)
    # @param stdin [IO] input stream (default $stdin)
    def initialize(argv: ARGV, stdout: $stdout, stderr: $stderr, stdin: $stdin)
      @argv = argv
      @stdout = stdout
      @stderr = stderr
      @stdin = stdin
      @option_parser = OptionParser.new
    end

    # Parse options, execute the requested action, and return an exit code.
    # @return [Integer] 0 on success, 1 on error
    def run
      @options = @option_parser.parse!(argv)
      Color.auto_detect(stdout)
      Color.enabled = false if @options[:no_color]
      execute
      0
    rescue Error => e
      stderr.puts "Error: #{e.message}"
      1
    rescue ::OptionParser::InvalidOption => e
      stderr.puts e.message
      stderr.puts @option_parser.help
      1
    end

    private

    def execute
      return show_version if @options[:version]
      return show_help if @options[:help]
      return list_profiles if @options[:list_profiles]

      db = load_database
      return show_count(db) if @options[:count]
      return list_folders(db) if @options[:list_folders]

      browse(db)
    end

    def show_version
      stdout.puts "bookmarker #{VERSION}"
    end

    def show_help
      stdout.puts @option_parser.help
    end

    def list_profiles
      finder = ProfileFinder.new
      dbs = finder.find_databases
      if dbs.empty?
        stdout.puts 'No Firefox profiles with bookmarks found.'
      else
        stdout.puts 'Firefox bookmark databases:'
        dbs.each { |path| stdout.puts "  #{path}" }
      end
    end

    def load_database
      path = @options[:database] || ProfileFinder.new.default_database
      Database.new(path)
    end

    def show_count(db)
      stdout.puts "Total bookmarks: #{db.count}"
    end

    def list_folders(db)
      folders = db.folders
      if folders.empty?
        stdout.puts 'No folders found.'
      else
        stdout.puts 'Bookmark folders:'
        folders.each { |f| stdout.puts "  #{f}" }
      end
    end

    def resolve_bookmarks(db)
      if @options[:search]
        db.search(@options[:search])
      elsif @options[:folder]
        db.by_folder(@options[:folder])
      else
        db.bookmarks
      end
    end

    def browse(db)
      bookmarks = resolve_bookmarks(db)
      page_size = @options[:per_page] || Pager::DEFAULT_PAGE_SIZE
      pager = Pager.new(bookmarks, page_size: page_size)
      pager.interactive(input: stdin, output: stdout)
    end
  end
end
