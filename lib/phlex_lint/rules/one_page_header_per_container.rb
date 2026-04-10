# frozen_string_literal: true

module PhlexLint
  module Rules
    # PageContainer should have at most one PageHeader child.
    #
    # PageHeader is the main page title. Multiple headers create visual hierarchy confusion.
    # Breadcrumb is allowed before PageHeader, but there should only be one main header.
    #
    # @example Bad
    #   PageContainer do
    #     PageHeader(title: "Section 1")
    #     PageHeader(title: "Section 2")  # Second header
    #   end
    #
    # @example Good
    #   PageContainer do
    #     Breadcrumb(items: [...])
    #     PageHeader(title: "Main Title")
    #     GlassCard { ... }
    #   end
    class OnePageHeaderPerContainer < Rule
      category "Structure"

      MESSAGE = "PageContainer should have at most one PageHeader child. " \
                "Multiple headers create visual hierarchy confusion."

      def check(tree)
        tree.each_node(:PageContainer) do |container_node|
          headers = container_node.direct_children_named(:PageHeader)
          next unless headers.size > 1

          # Report violation on the second and subsequent headers
          headers[1..-1].each do |header_node|
            violation(header_node, MESSAGE)
          end
        end
      end
    end
  end
end
