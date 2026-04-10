# frozen_string_literal: true

module PhlexLint
  module Rules
    # PageContainer must not be inside a FlexRow.
    #
    # PageContainer applies `container-fluid` which uses `margin-left: auto` and
    # `margin-right: auto`. Inside a flex container, this absorbs all available
    # space before the element, pushing it to the far right — breaking layout
    # in ways that are visually subtle but structurally broken.
    #
    # PageContainer is always a top-level page wrapper. If you need elements
    # beside it, restructure the layout so PageContainer wraps everything.
    #
    # @example Bad
    #   FlexRow(gap: :md) do
    #     Sidebar(...)
    #     PageContainer do     # container-fluid + auto margins breaks flex layout
    #       PageHeader(...)
    #     end
    #   end
    #
    # @example Good
    #   PageContainer do
    #     FlexRow(gap: :md) do
    #       Sidebar(...)
    #       FlexColumn(gap: :lg) { ... }
    #     end
    #   end
    class PageContainerInFlexRow < Rule
      category "Structure"

      MESSAGE = "PageContainer must not be inside a FlexRow. PageContainer uses container-fluid " \
                "with auto margins which absorbs flex space, pushing content to the right. " \
                "Make PageContainer the outermost wrapper instead."

      def check(tree)
        tree.each_node(:PageContainer) do |node|
          next unless node.ancestor?(:FlexRow)

          violation(node, MESSAGE)
        end
      end
    end
  end
end
