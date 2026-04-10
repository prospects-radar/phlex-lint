# frozen_string_literal: true

module PhlexLint
  module Rules
    # Heading color must be a valid value.
    #
    # Heading accepts specific color values to maintain design system consistency.
    # Invalid colors produce no visible styling change.
    #
    # @example Bad
    #   Heading(level: 2, text: "Title", color: :dark_red)
    #
    # @example Good
    #   Heading(level: 2, text: "Title", color: :dark)
    class HeadingColorValidation < Rule
      category "DesignSystem"

      VALID_COLORS = %i[default dark light muted danger success warning info].freeze

      MESSAGE = "Heading color must be one of: %<valid>s. Got: %<actual>s"

      def check(tree)
        tree.each_node(:Heading) do |node|
          color = node.kwarg(:color)
          next unless color
          next if VALID_COLORS.include?(color)

          violation(node, format(MESSAGE, valid: VALID_COLORS.join(", "), actual: color))
        end
      end
    end
  end
end
