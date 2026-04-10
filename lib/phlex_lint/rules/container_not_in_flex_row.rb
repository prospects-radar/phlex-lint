# frozen_string_literal: true

module PhlexLint
  module Rules
    # Container must not be a direct child of FlexRow.
    #
    # Container applies margin: auto; margin-right: auto which, in a flex context,
    # absorbs all available space to the left, pushing flex siblings to the right.
    # This breaks the flex layout. Use FlexColumn or raw div instead.
    #
    # @example Bad
    #   FlexRow(gap: :md) do
    #     Icon(name: "search")
    #     Container do
    #       Button(text: "Search")
    #     end
    #   end
    #
    # @example Good
    #   FlexRow(gap: :md) do
    #     Icon(name: "search")
    #     div do
    #       Button(text: "Search")
    #     end
    #   end
    class ContainerNotInFlexRow < Rule
      category "Structure"

      MESSAGE = "Container must not be a direct child of FlexRow. Container's margin: auto; " \
                "absorbs all space to the left, pushing siblings right. Use FlexColumn or div instead."

      def check(tree)
        tree.each_node(:Container) do |node|
          next unless node.ancestor?(:FlexRow)

          violation(node, MESSAGE)
        end
      end
    end
  end
end
