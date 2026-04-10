# frozen_string_literal: true

module PhlexLint
  module Rules
    # Enforce use of design token classes instead of Bootstrap text color utilities.
    #
    # Bootstrap text color utilities (text-white, text-muted, text-dark, etc.) do not
    # adapt to the GlassMorph theme and bypass the design token system. Use the
    # corresponding gm-text-* tokens instead.
    #
    # @example Bad
    #   span(class: "text-muted")
    #   p(class: "text-dark fw-bold")
    #
    # @example Good
    #   span(class: "gm-text-muted")
    #   p(class: "gm-text-primary fw-bold")
    class EnforceDesignTokenClasses < Rule
      category "Style"

      # Matches legacy Bootstrap text color tokens as whole class tokens (not as substrings of gm-text-*).
      LEGACY_TOKENS = %w[text-white text-muted text-dark text-light text-body text-black-50 text-white-50].freeze
      MESSAGE = "Use design token classes (gm-text-primary, gm-text-muted, etc.) instead of Bootstrap text color utilities."

      def check(tree)
        tree.each_node do |node|
          class_val = node.kwarg(:class)
          next unless class_val.is_a?(String)

          tokens = class_val.split
          next unless tokens.any? { |t| LEGACY_TOKENS.include?(t) }

          violation(node, MESSAGE)
        end
      end
    end
  end
end
