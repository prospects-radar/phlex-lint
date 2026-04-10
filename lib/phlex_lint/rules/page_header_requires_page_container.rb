# frozen_string_literal: true

module PhlexLint
  module Rules
    # PageHeader must have PageContainer as an ancestor.
    #
    # PageHeader's teal gradient styling is applied via the `.page-inner` CSS context
    # that PageContainer provides. Without it, PageHeader renders as unstyled text.
    #
    # @example Bad
    #   def view_template
    #     FlexColumn(gap: :lg) do
    #       PageHeader(title: t("page.title"))   # no PageContainer ancestor
    #     end
    #   end
    #
    # @example Good
    #   def view_template
    #     PageContainer do
    #       PageHeader(title: t("page.title"))
    #     end
    #   end
    class PageHeaderRequiresPageContainer < Rule
      category "Structure"

      MESSAGE = "PageHeader must be inside a PageContainer. Without it, the teal gradient " \
                "header styling (from .page-inner CSS context) will not apply."

      def self.documentation_url
        ".claude/skills/design-system/references/page-templates.md"
      end

      def check(tree)
        tree.each_node(:PageHeader) do |node|
          next if node.ancestor?(:PageContainer)

          violation(node, MESSAGE)
        end
      end
    end
  end
end
