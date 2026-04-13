# frozen_string_literal: true

module PhlexLint
  module Rules
    # PageContainer must contain a PageHeader.
    #
    # Every page should have a PageHeader to provide consistent navigation context
    # and visual hierarchy. A PageContainer without a PageHeader is a page missing
    # its title and description.
    #
    # @example Bad
    #   def view_template
    #     PageContainer do
    #       GlassCard { "content" }
    #     end
    #   end
    #
    # @example Good
    #   def view_template
    #     PageContainer do
    #       PageHeader(title: t("page.title"))
    #       GlassCard { "content" }
    #     end
    #   end
    class PageContainerRequiresPageHeader < Rule
      category "Structure"

      MESSAGE = "PageContainer must contain a PageHeader. Every page needs a title for " \
                "consistent navigation context and visual hierarchy."

      def self.documentation_url
        ".claude/skills/design-system/references/page-templates.md"
      end

      def check(tree)
        tree.each_node(:PageContainer) do |node|
          has_page_header = node.each_node(:PageHeader).any?
          violation(node, MESSAGE) unless has_page_header
        end
      end
    end
  end
end
