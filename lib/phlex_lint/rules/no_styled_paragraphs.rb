# frozen_string_literal: true

module PhlexLint
  module Rules
    # Detect raw p elements with Bootstrap text utility classes.
    #
    # Using `p(class: "text-muted small")` bypasses the design system Paragraph
    # atom, which enforces consistent color tokens and size props.
    #
    # @example Bad
    #   p(class: "text-muted small") { "Note" }
    #   p(class: "fs-6 text-light") { "Hint" }
    #
    # @example Good
    #   Paragraph(color: :muted, size: :sm) { "Note" }
    class NoStyledParagraphs < Rule
      category "DesignSystem"

      MESSAGE = "Use Paragraph(color: ..., size: ...) atom instead of raw p() with Bootstrap utilities."

      STYLED_PARAGRAPH_PATTERN = /\b(text-muted|text-light|text-dark|text-white|small|fs-\d)/.freeze

      def check(tree)
        tree.each_node(:p) do |node|
          class_val = node.kwarg(:class)
          next unless class_val.is_a?(String)
          next unless class_val.match?(STYLED_PARAGRAPH_PATTERN)

          violation(node, MESSAGE)
        end
      end
    end
  end
end
