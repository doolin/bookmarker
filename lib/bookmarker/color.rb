# frozen_string_literal: true

module Bookmarker
  # ANSI color support with colorblind-friendly defaults.
  #
  # Uses semantic style names (:url, :path, :key) that map to
  # accessible colors chosen from the Okabe-Ito palette principles.
  # Primary differentiation is bold/dim weight, with hue as a
  # secondary channel — the hierarchy reads correctly in grayscale.
  #
  # Two tiers: 256-color (default on modern terminals) and basic
  # 8-color fallback. Respects NO_COLOR (no-color.org) and non-TTY.
  #
  # @example
  #   Color.auto_detect($stdout)
  #   Color.wrap('hello', :bold)       # => "\e[1mhello\e[0m" (if enabled)
  #   Color.wrap('link', :url)         # => "\e[38;5;74mlink\e[0m"
  #   Color.wrap('key', :key, :bold)   # => "\e[38;5;73m\e[1mkey\e[0m"
  module Color
    RESET = "\e[0m"

    STYLES = {
      bold: "\e[1m",
      dim: "\e[2m"
    }.freeze

    SEMANTIC_256 = {
      url: "\e[38;5;74m",   # steel blue
      path: "\e[38;5;179m", # warm gold
      key: "\e[38;5;73m"    # teal
    }.freeze

    SEMANTIC_BASIC = {
      url: "\e[36m",  # cyan
      path: "\e[33m", # yellow
      key: "\e[32m"   # green
    }.freeze

    class << self
      attr_writer :enabled

      def enabled?
        @enabled || false
      end

      # Detect color support from the output stream and environment.
      # Call once at startup (e.g. in CLI#run).
      def auto_detect(output)
        @enabled = !ENV.key?('NO_COLOR') &&
                   output.respond_to?(:tty?) &&
                   output.tty?
        @depth = detect_depth
      end

      # @return [:color256, :basic] terminal color depth
      def depth
        @depth || detect_depth
      end

      # Wrap text in ANSI escape codes. Returns plain text when disabled.
      # @param text [String] the text to wrap
      # @param styles [Array<Symbol>] style names (:bold, :dim, :url, :path, :key)
      # @return [String]
      def wrap(text, *styles)
        return text.to_s unless enabled?

        codes = styles.map { |s| resolve(s) }.join
        "#{codes}#{text}#{RESET}"
      end

      private

      def detect_depth
        term = ENV.fetch('TERM', '')
        colorterm = ENV.fetch('COLORTERM', '')
        if colorterm != '' || term.include?('256color')
          :color256
        else
          :basic
        end
      end

      def resolve(style)
        STYLES[style] || semantic(style) || ''
      end

      def semantic(style)
        palette = depth == :color256 ? SEMANTIC_256 : SEMANTIC_BASIC
        palette[style]
      end
    end
  end
end
