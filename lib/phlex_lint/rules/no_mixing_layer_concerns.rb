# frozen_string_literal: true

module PhlexLint
  module Rules
    # Don't mix ITCSS layer concerns in a single element.
    #
    # Following Inverted Triangle CSS (ITCSS), elements should not mix:
    # - Element selectors (div, p, span) styling classes
    # - Component classes (card, btn, badge)
    # - Utility classes (mb-4, text-muted, d-flex)
    #
    # While Bootstrap allows some mixing, excessive mixing creates maintainability
    # issues. Prefer component parameters over utility-heavy class strings.
    #
    # @example Potentially Problematic
    #   div(class: "card mb-4 shadow-sm d-flex align-items-center")
    #   p(class: "card-text text-muted mt-2 fw-bold")
    #
    # @example Better (use component parameters)
    #   GlassCard(variant: :elevated) { ... }
    #   Text(level: :p, color: :muted, weight: :bold)
    class NoMixingLayerConcerns < Rule
      category "ITCSS"

      # High utility density patterns (many utilities, few component classes)
      UTILITY_DENSITY_THRESHOLD = 3

      # Bootstrap utility patterns
      UTILITY_PATTERN = /\b(d-[a-z]+|m[tblrxy]?-\d+|p[tblrxy]?-\d+|gap-\d+|text-[a-z]+|bg-[a-z]+|fw-\w+|fs-\d+|shadow-\w+|rounded-\w+|border(-[a-z]+)?|align-[a-z]+|justify-[a-z]+|flex-[a-z]+|w-\d+|h-\d+)\b/

      # Component class patterns
      COMPONENT_PATTERN = /\b(btn|card|badge|alert|nav|navbar|dropdown|modal|table|form|accordion|tab|spinner|collapse)\b/

      MESSAGE = "High density of utility classes (%<count>d utilities). " \
                "Consider using component parameters instead. " \
                "Mixing many utilities with component classes violates ITCSS separation. " \
                "Use the design system component's API (color:, variant:, etc.) instead."

      def check(tree)
        tree.each_node do |node|
          class_val = node.kwarg(:class)
          next if class_val.nil?
          next if class_val == :__dynamic__ || class_val == :__interpolated__
          next unless class_val.is_a?(String)

          tokens = class_val.split

          # Count utilities and components
          utility_count = tokens.count { |t| t.match?(UTILITY_PATTERN) }
          component_count = tokens.count { |t| t.match?(COMPONENT_PATTERN) }

          # Only flag when there are many utilities and at least one component
          next unless utility_count >= UTILITY_DENSITY_THRESHOLD
          next if component_count.zero?

          violation(node, format(MESSAGE, count: utility_count))
        end
      end
    end
  end
end
