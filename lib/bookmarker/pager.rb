# frozen_string_literal: true

module Bookmarker
  # Paginates an array of items for terminal display.
  #
  # Provides both a programmatic API (next_page, prev_page, go_to)
  # and a full interactive loop with keyboard navigation.
  #
  # @example Programmatic
  #   pager = Pager.new(bookmarks, page_size: 10)
  #   pager.render                # print page 1
  #   pager.next_page             # advance
  #   pager.render                # print page 2
  #
  # @example Interactive
  #   pager = Pager.new(bookmarks)
  #   pager.interactive           # n/p/q/page# loop
  class Pager
    # @return [Integer] default number of items per page
    DEFAULT_PAGE_SIZE = 25

    # @return [Array] the full collection being paginated
    # @return [Integer] items per page
    # @return [Integer] zero-based current page index
    attr_reader :items, :page_size, :current_page

    # @param items [Array] collection of objects responding to #formatted
    # @param page_size [Integer] items per page (default 25)
    def initialize(items, page_size: DEFAULT_PAGE_SIZE)
      @items = items
      @page_size = page_size
      @current_page = 0
    end

    # @return [Integer] total number of pages (0 if empty)
    def total_pages
      return 0 if items.empty?

      (items.size.to_f / page_size).ceil
    end

    # @return [Array] items on the current page
    def current_items
      start = current_page * page_size
      items[start, page_size] || []
    end

    # Advance to the next page.
    # @return [Boolean] true if the page changed, false if already on last page
    def next_page
      return false unless next_page?

      @current_page += 1
      true
    end

    # Go back to the previous page.
    # @return [Boolean] true if the page changed, false if already on first page
    def prev_page
      return false unless prev_page?

      @current_page -= 1
      true
    end

    # @return [Boolean] true if there is a next page
    def next_page?
      current_page < total_pages - 1
    end

    # @return [Boolean] true if there is a previous page
    def prev_page?
      current_page > 0
    end

    # Jump to a specific page.
    # @param page_number [Integer] zero-based page index
    # @return [Boolean] true if the page was valid and set
    def go_to(page_number)
      return false if page_number < 0 || page_number >= total_pages

      @current_page = page_number
      true
    end

    # @return [String] human-readable page status, e.g. "Showing 1-25 of 50 (page 1/2)"
    def page_status
      return "No items" if items.empty?

      first = current_page * page_size + 1
      last = [first + page_size - 1, items.size].min
      "Showing #{first}-#{last} of #{items.size} (page #{current_page + 1}/#{total_pages})"
    end

    # Render the current page to an output stream.
    # @param output [IO] output stream (default $stdout)
    def render(output: $stdout)
      if items.empty?
        output.puts "No bookmarks found."
        return
      end

      offset = current_page * page_size
      current_items.each_with_index do |item, i|
        output.puts item.formatted(offset + i + 1)
        output.puts
      end

      output.puts page_status
    end

    # Run an interactive pagination loop reading commands from input.
    #
    # Commands: n/next, p/prev, q/quit/exit, or a page number (1-based).
    #
    # @param input [IO] input stream (default $stdin)
    # @param output [IO] output stream (default $stdout)
    def interactive(input: $stdin, output: $stdout)
      loop do
        render(output: output)
        output.puts
        output.print navigation_prompt
        break unless process_input(input, output)
      end
    end

    private

    def navigation_prompt
      parts = []
      parts << "[n]ext" if next_page?
      parts << "[p]rev" if prev_page?
      parts << "[q]uit"
      "#{parts.join(" | ")} > "
    end

    def process_input(input, output)
      line = input.gets
      return false if line.nil?

      case line.strip.downcase
      when "n", "next"
        unless next_page
          output.puts "Already on last page."
        end
        true
      when "p", "prev"
        unless prev_page
          output.puts "Already on first page."
        end
        true
      when "q", "quit", "exit"
        false
      when /\A\d+\z/
        page_num = line.strip.to_i - 1
        unless go_to(page_num)
          output.puts "Invalid page number. Valid range: 1-#{total_pages}"
        end
        true
      else
        output.puts "Unknown command. Use n/p/q or a page number."
        true
      end
    end
  end
end
