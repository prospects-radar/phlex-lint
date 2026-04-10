# frozen_string_literal: true

module PhlexLint
  module Rules
    # Flag utility classes where component classes should be used.
    #
    # In ITCSS, the Component layer should prefer semantic component classes
    # over utility classes for layout structure. Utilities should be used for
    # fine-tuning, not for defining the core structure.
    #
    # This rule flags cases where a major layout decision is made using
    # utilities instead of a design system component.
    #
    # @example Potentially Problematic
    #   div(class: "card d-flex flex-column gap-3")  # Should use FlexColumn
    #   div(class: "d-flex align-items-center gap-2")  # Should use FlexRow
    #   div(class: "container mt-4")  # Should use Container
    #
    # @example Better
    #   FlexColumn(gap: :md)
    #   FlexRow(gap: :sm)
    #   Container { ... }
    class UtilityInComponentPosition < Rule
      category "ITCSS"

      # Patterns that suggest a component should be used instead
      PATTERNS = [
        {
          pattern: /\bcard\s+d-flex\s+flex-(?:column|row)/i,
          suggestion: "Use Card + FlexColumn/FlexRow instead",
          component: "Card with flex layout"
        },
        {
          pattern: /\bd-flex\s+(?:align-items-center|align-items-start|align-items-end)\s+gap-\d+/i,
          suggestion: "Use FlexRow(gap:) instead",
          component: "FlexRow"
        },
        {
          pattern: /\bd-flex\s+flex-column\s+gap-\d+/i,
          suggestion: "Use FlexColumn(gap:) instead",
          component: "FlexColumn"
        },
        {
          pattern: /\bcontainer\s+(?:mt|mb|pt|pb)-\d+/i,
          suggestion: "Use Container with PageContainer instead",
          component: "Container/PageContainer"
        },
        {
          pattern: /\bcontainer\s+d-flex\b/i,
          suggestion: "Use PageContainer instead",
          component: "PageContainer"
        }
      ].freeze

      MESSAGE = "Utility classes define major layout structure. " \
                "Use %<suggestion>s. " \
                "Pattern: %<pattern>s"

      def check(tree)
        tree.each_node do |node|
          # Only check raw div elements, not design system components
          next unless node.name == :div

          class_val = node.kwarg(:class)
          next if class_val.nil?
          next if class_val == :__dynamic__ || class_val == :__interpolated__
          next unless class_val.is_a?(String)

          PATTERNS.each do |rule|
            next unless class_val.match?(rule[:pattern])

            violation(node, format(MESSAGE, suggestion: rule[:suggestion], pattern: class_val))
            break  # Only report first match
          end
        end
      end
    end
  end
end
