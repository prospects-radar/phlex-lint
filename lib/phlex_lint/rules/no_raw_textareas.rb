# frozen_string_literal: true

module PhlexLint
  module Rules
    # Detect any raw textarea element.
    #
    # Raw `textarea` elements lack the design system's gradient focus effects,
    # validation states, and consistent sizing provided by the TextArea atom.
    #
    # @example Bad
    #   textarea(name: "body", rows: 5)
    #
    # @example Good
    #   TextArea(name: "body", rows: 5)
    class NoRawTextareas < Rule
      category "DesignSystem"

      MESSAGE = "Use TextArea() atom instead of raw textarea — provides gradient focus effects and validation states."

      def check(tree)
        tree.each_node(:textarea) do |node|
          violation(node, MESSAGE)
        end
      end
    end
  end
end
