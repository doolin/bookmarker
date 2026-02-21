# frozen_string_literal: true

module Bookmarker
  class Exporter
    # Default exporter: interactive paged display in the terminal.
    #
    # Wraps Pager to present bookmarks with keyboard navigation.
    # This is the export format used when no --export flag is given.
    #
    # @example
    #   exporter = Exporter::Stdout.new(bookmarks, output: $stdout, input: $stdin)
    #   exporter.export
    class Stdout < Exporter
      # @param bookmarks [Array<Bookmark>] bookmarks to display
      # @param output [IO] output stream (default $stdout)
      # @param input [IO] input stream for interactive navigation (default $stdin)
      # @param page_size [Integer] items per page (default Pager::DEFAULT_PAGE_SIZE)
      def initialize(bookmarks, output: $stdout, input: $stdin, page_size: nil, **)
        super(bookmarks, output: output)
        @input = input
        @page_size = page_size || Pager::DEFAULT_PAGE_SIZE
      end

      # Run the interactive pager loop.
      def export
        pager = Pager.new(bookmarks, page_size: @page_size)
        pager.interactive(input: @input, output: output)
      end
    end
  end
end
