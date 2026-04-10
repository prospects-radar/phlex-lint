# frozen_string_literal: true

module PhlexLint
  module Rules
    # Detect raw h1-h6 elements that use Bootstrap font utility classes.
    #
    # Raw heading elements with Bootstrap font utilities (`fw-bold`, `fs-3`,
    # `text-white`, etc.) bypass the design system Heading atom, which enforces
    # consistent typography tokens and color semantics.
    #
    # @example Bad
    #   h2(class: "fw-bold text-white") { "Section Title" }
    #   h3(class: "fs-5 text-muted") { "Subtitle" }
    #
    # @example Good
    #   Heading(level: 2, text: "Section Title")
    #   Heading(level: 3, text: "Subtitle", color: :muted)
    class UseRealHeading < Rule
      category "DesignSystem"

      MESSAGE = "Use Heading(level: %<level>s, ...) atom instead of raw h%<level>s with Bootstrap font utilities."

      FONT_UTILITIES_PATTERN = /\b(fw-|fs-|text-(?:white|muted|dark|light|primary|secondary|success|danger|warning|info))/.freeze

      HEADING_TAGS = %i[h1 h2 h3 h4 h5 h6].freeze

      def check(tree)
        HEADING_TAGS.each do |tag|
          tree.each_node(tag) do |node|
            class_val = node.kwarg(:class)
            next unless class_val.is_a?(String)
            next unless class_val.match?(FONT_UTILITIES_PATTERN)

            level = tag.to_s.sub("h", "")
            violation(node, format(MESSAGE, level: level))
          end
        end
      end
    end
  end
end
