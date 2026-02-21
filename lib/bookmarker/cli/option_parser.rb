# frozen_string_literal: true

require 'optparse'

module Bookmarker
  class CLI
    # Builds and runs the OptionParser for the bookmarker CLI.
    #
    # Returns a plain Hash of parsed options so that CLI stays
    # focused on orchestration rather than argument definition.
    #
    # @example
    #   op = OptionParser.new
    #   options = op.parse!(%w[--database /tmp/places.sqlite --count])
    #   options[:database] # => "/tmp/places.sqlite"
    #   options[:count]    # => true
    class OptionParser
      # Parse argv in place, returning the options hash.
      # @param argv [Array<String>] command-line arguments (mutated)
      # @return [Hash] parsed option keys and values
      def parse!(argv)
        parser.parse!(argv)
        options
      end

      # @return [String] formatted help/usage text
      def help
        parser.to_s
      end

      private

      def options
        @options ||= {}
      end

      def parser # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
        @parser ||= ::OptionParser.new do |opts|
          opts.banner = 'Usage: bookmarker [options]'
          opts.separator ''
          opts.separator 'Options:'

          opts.on('-d', '--database PATH', 'Path to places.sqlite') { |p| options[:database] = p }
          opts.on('-s', '--search TERM', 'Search bookmarks by title, URL, or folder') { |t| options[:search] = t }
          opts.on('-f', '--folder NAME', 'Show bookmarks in a specific folder') { |n| options[:folder] = n }
          opts.on('--folders', 'List all bookmark folders') { options[:list_folders] = true }
          opts.on('-n', '--per-page NUM', Integer, 'Bookmarks per page (default: 25)') { |n| options[:per_page] = n }
          opts.on('--profiles', 'List available Firefox profiles with databases') { options[:list_profiles] = true }
          opts.on('-c', '--count', 'Show total bookmark count and exit') { options[:count] = true }
          opts.on('-e', '--export FORMAT', 'Export bookmarks (json)') { |f| options[:export] = f }
          opts.on('-v', '--version', 'Show version') { options[:version] = true }
          opts.on('--no-color', 'Disable colored output') { options[:no_color] = true }
          opts.on('-h', '--help', 'Show this help') { options[:help] = true }
        end
      end
    end
  end
end
