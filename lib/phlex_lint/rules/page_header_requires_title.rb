# frozen_string_literal: true

module PhlexLint
  module Rules
    # PageHeader must have a title: kwarg.
    #
    # PageHeader's primary purpose is to display the page title. Without it,
    # the component serves no purpose and indicates incomplete implementation.
    #
    # @example Bad
    #   PageHeader()
    #   PageHeader(subtitle: "Details")
    #
    # @example Good
    #   PageHeader(title: t("pages.accounts.title"))
    #   PageHeader(title: "Details", subtitle: t("pages.accounts.subtitle"))
    class PageHeaderRequiresTitle < Rule
      category "ComponentAPI"

      MESSAGE = "PageHeader must have a title: kwarg that displays the page title."

      def check(tree)
        tree.each_node(:PageHeader) do |node|
          next if node.kwargs.key?(:title)

          violation(node, MESSAGE)
        end
      end
    end
  end
end
