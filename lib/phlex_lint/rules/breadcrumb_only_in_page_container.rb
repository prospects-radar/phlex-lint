# frozen_string_literal: true

module PhlexLint
  module Rules
    # Breadcrumb must be inside a PageContainer.
    #
    # Breadcrumb's styling (color, spacing) is designed for the PageContainer context.
    # Outside of it, breadcrumb loses its visual styling and context.
    #
    # @example Bad
    #   FlexColumn do
    #     Breadcrumb(items: [...])
    #     PageHeader(title: "Details")
    #   end
    #
    # @example Good
    #   PageContainer do
    #     Breadcrumb(items: [...])
    #     PageHeader(title: "Details")
    #   end
    class BreadcrumbOnlyInPageContainer < Rule
      category "Structure"

      MESSAGE = "Breadcrumb must be inside a PageContainer. Without it, breadcrumb loses " \
                "its styling context and visual treatment."

      def check(tree)
        tree.each_node(:Breadcrumb) do |node|
          next if node.ancestor?(:PageContainer)

          violation(node, MESSAGE)
        end
      end
    end
  end
end
