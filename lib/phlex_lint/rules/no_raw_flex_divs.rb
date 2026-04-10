# frozen_string_literal: true

module PhlexLint
  module Rules
    # Detect raw div/span elements with Bootstrap d-flex class.
    #
    # Using raw `div(class: "d-flex ...")` bypasses the design system layout
    # components that enforce consistent gap tokens and semantic layout intent.
    #
    # @example Bad
    #   div(class: "d-flex align-items-center")
    #   span(class: "d-flex gap-2")
    #
    # @example Good
    #   FlexRow(gap: :md)
    #   FlexColumn(gap: :sm)
    class NoRawFlexDivs < Rule
      category "DesignSystem"

      MESSAGE = "Use FlexRow(gap: :md) or FlexColumn(gap: :sm) instead of raw div with d-flex class."

      def check(tree)
        %i[div span].each do |tag|
          tree.each_node(tag) do |node|
            class_val = node.kwarg(:class)
            next unless class_val.is_a?(String)
            next unless class_val.match?(/\bd-flex\b/)

            violation(node, MESSAGE)
          end
        end
      end
    end
  end
end
