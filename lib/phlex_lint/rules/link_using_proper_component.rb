# frozen_string_literal: true

module PhlexLint
  module Rules
    # Use Link component instead of raw <a> tag.
    #
    # <a> is valid HTML but loses design system styling and consistency.
    # Use the Link component which provides consistent styling, hover states, and accessibility.
    #
    # @example Bad
    #   a(href: "/path") { "Click here" }
    #
    # @example Good
    #   Link(href: "/path", text: "Click here")
    class LinkUsingProperComponent < Rule
      category "DesignSystem"

      MESSAGE = "Use Link component instead of raw <a> tag. " \
                "Link provides consistent styling, hover states, and accessibility."

      def check(tree)
        # Like SeparatorUsingProperComponent, this requires detecting raw HTML method calls
        # which is complex without full Ruby AST analysis
        # RuboCop's DesignSystem/NoHardcodedHtmlComponents already catches this
      end
    end
  end
end
