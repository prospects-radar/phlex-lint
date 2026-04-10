# frozen_string_literal: true

module PhlexLint
  module Rules
    # EmptyState must not be nested inside another EmptyState.
    #
    # EmptyState is designed to fill an entire section or page with a centered
    # icon + message + CTA. Nesting produces invisible inner empty states or
    # broken double-empty-state layouts.
    #
    # @example Bad
    #   EmptyState(icon: "inbox", message: t("no_data")) do
    #     EmptyState(icon: "search", message: t("try_search"))
    #   end
    #
    # @example Good
    #   if @data.empty?
    #     EmptyState(icon: "inbox", message: t("no_data"))
    #   else
    #     # render data
    #   end
    class NestedEmptyState < Rule
      category "Structure"

      MESSAGE = "EmptyState must not be nested inside another EmptyState. " \
                "Each section should have at most one EmptyState component."

      def check(tree)
        tree.each_node(:EmptyState) do |node|
          next unless node.ancestor?(:EmptyState)

          violation(node, MESSAGE)
        end
      end
    end
  end
end
