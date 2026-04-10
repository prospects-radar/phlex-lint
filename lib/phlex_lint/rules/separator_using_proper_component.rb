# frozen_string_literal: true

module PhlexLint
  module Rules
    # Use Separator component instead of raw <hr> tag.
    #
    # <hr> is a semantic HTML element but semantically incorrect in Phlex.
    # Use the Separator component which provides proper styling and semantics.
    #
    # @example Bad
    #   hr  # Raw HTML element
    #   hr() # Raw HTML element call
    #
    # @example Good
    #   Separator()
    #   Separator(color: :muted)
    class SeparatorUsingProperComponent < Rule
      category "DesignSystem"

      MESSAGE = "Use Separator component instead of raw <hr> tag. " \
                "Separator provides proper styling and component integration."

      def check(tree)
        # This is harder to detect without full Ruby AST inspection of method calls
        # We'd need to detect bare `hr` calls which Phlex translates to <hr>
        # For now, this is a placeholder that would need deeper AST analysis
        # In practice, RuboCop's DesignSystem/NoHardcodedHtmlComponents catches this
      end
    end
  end
end
