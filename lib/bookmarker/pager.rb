# frozen_string_literal: true

require 'io/console'

module Bookmarker
  # Paginates an array of items for terminal display.
  #
  # Provides both a programmatic API (advance?, go_back?, go_to?)
  # and a full interactive loop with keyboard navigation.
  #
  # @example Programmatic
  #   pager = Pager.new(bookmarks, page_size: 10)
  #   pager.render                # print page 1
  #   pager.advance?              # move to page 2
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
    def advance?
      return false unless next_page?

      @current_page += 1
      true
    end

    # Go back to the previous page.
    # @return [Boolean] true if the page changed, false if already on first page
    def go_back?
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
      current_page.positive?
    end

    # Jump to a specific page.
    # @param page_number [Integer] zero-based page index
    # @return [Boolean] true if the page was valid and set
    def go_to?(page_number)
      return false if page_number.negative? || page_number >= total_pages

      @current_page = page_number
      true
    end

    # @return [String] human-readable page status, e.g. "Showing 1-25 of 50 (page 1/2)"
    def page_status
      return 'No items' if items.empty?

      first = (current_page * page_size) + 1
      last = [first + page_size - 1, items.size].min
      "Showing #{first}-#{last} of #{items.size} (page #{current_page + 1}/#{total_pages})"
    end

    # Render the current page to an output stream.
    # @param output [IO] output stream (default $stdout)
    def render(output: $stdout)
      if items.empty?
        output.puts 'No bookmarks found.'
        return
      end

      offset = current_page * page_size
      current_items.each_with_index do |item, i|
        output.puts item.formatted(offset + i + 1)
        output.puts
      end

      output.puts page_status
    end

    # Run an interactive pagination loop reading single keypresses.
    #
    # Commands: n (next), p (prev), q (quit) act instantly.
    # Page numbers (1-based) accumulate digits until Enter.
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
      parts << '[n]ext' if next_page?
      parts << '[p]rev' if prev_page?
      parts << '[q]uit'
      "#{parts.join(' | ')} > "
    end

    def read_char(input)
      if input.respond_to?(:getch)
        input.getch
      else
        input.getc
      end
    end

    def process_input(input, output)
      char = read_char(input)
      return false if char.nil?

      case char.downcase
      when 'n'
        output.puts
        output.puts 'Already on last page.' unless advance?
        true
      when 'p'
        output.puts
        output.puts 'Already on first page.' unless go_back?
        true
      when 'q'
        output.puts
        false
      when /\d/
        handle_page_number(char, input, output)
      else
        output.puts
        output.puts 'Unknown command. Use n/p/q or a page number.'
        true
      end
    end

    def handle_page_number(first_digit, input, output)
      output.print first_digit
      digits = first_digit
      loop do
        c = read_char(input)
        break unless c&.match?(/\d/)

        digits << c
        output.print c
      end
      output.puts
      page_num = digits.to_i - 1
      output.puts "Invalid page number. Valid range: 1-#{total_pages}" unless go_to?(page_num)
      true
    end
  end
end
