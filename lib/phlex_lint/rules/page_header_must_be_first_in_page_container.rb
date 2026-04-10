# frozen_string_literal: true

module PhlexLint
  module Rules
    # PageHeader must be the first non-Breadcrumb child of PageContainer.
    #
    # The visual hierarchy of a page requires the gradient header to appear at the top.
    # The only element allowed before PageHeader is a Breadcrumb (navigation context).
    # All other content (GlassCard sections, etc.) must follow PageHeader.
    #
    # @example Bad — content before PageHeader
    #   PageContainer do
    #     GlassCard(variant: :section) { ... }
    #     PageHeader(title: t("page.title"))
    #   end
    #
    # @example Good — PageHeader first
    #   PageContainer do
    #     PageHeader(title: t("page.title"))
    #     GlassCard(variant: :section) { ... }
    #   end
    #
    # @example Good — Breadcrumb allowed before PageHeader
    #   PageContainer do
    #     Breadcrumb(items: [...])
    #     PageHeader(title: t("page.title"))
    #     GlassCard(variant: :section) { ... }
    #   end
    class PageHeaderMustBeFirstInPageContainer < Rule
      category "Structure"

      MESSAGE = "PageHeader must be the first child of PageContainer (only Breadcrumb may precede it). " \
                "Found %<preceding>s before PageHeader. Move PageHeader to the top of PageContainer."

      def check(tree)
        tree.each_node(:PageContainer) do |node|
          page_header_idx = node.children.index { |c| c.name == :PageHeader }
          next unless page_header_idx  # no PageHeader present — not our concern

          # Everything before PageHeader that is not Breadcrumb is an offender
          preceding_non_breadcrumb = node.children
            .first(page_header_idx)
            .reject { |c| c.name == :Breadcrumb }

          next if preceding_non_breadcrumb.empty?

          preceding_names = preceding_non_breadcrumb.map(&:name).join(", ")
          violation(
            node.children[page_header_idx],
            format(MESSAGE, preceding: preceding_names)
          )
        end
      end
    end
  end
end
