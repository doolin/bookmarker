# frozen_string_literal: true

require_relative 'exporter/stdout'

module Bookmarker
  # Base class for bookmark exporters.
  #
  # Each subclass implements #export to serialize bookmarks into a
  # specific format (interactive terminal, JSON, CSV, etc.).
  #
  # The factory method .for resolves a format name to the appropriate
  # subclass, allowing the CLI to remain format-agnostic.
  #
  # @example
  #   exporter = Exporter.for(:stdout, bookmarks, output: $stdout, input: $stdin)
  #   exporter.export
  class Exporter
    FORMATS = {
      stdout: Exporter::Stdout
    }.freeze

    # @return [Array<Bookmark>] bookmarks to export
    # @return [IO] output stream
    attr_reader :bookmarks, :output

    # @param bookmarks [Array<Bookmark>] bookmarks to export
    # @param output [IO] output stream (default $stdout)
    def initialize(bookmarks, output: $stdout, **)
      @bookmarks = bookmarks
      @output = output
    end

    # Serialize and write bookmarks to the output stream.
    # @raise [NotImplementedError] subclasses must override
    def export
      raise NotImplementedError, "#{self.class} must implement #export"
    end

    # Resolve a format name to an exporter instance.
    #
    # @param format [Symbol, String] export format name
    # @param bookmarks [Array<Bookmark>] bookmarks to export
    # @param options [Hash] keyword arguments forwarded to the exporter
    # @return [Exporter] an exporter instance for the given format
    # @raise [Error] if the format is not recognized
    def self.for(format, bookmarks, **)
      klass = FORMATS.fetch(format.to_sym) do
        raise Error, "Unknown export format: #{format}"
      end
      klass.new(bookmarks, **)
    end
  end
end
