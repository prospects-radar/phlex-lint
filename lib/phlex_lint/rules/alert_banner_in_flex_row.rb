# frozen_string_literal: true

module PhlexLint
  module Rules
    # AlertBanner must not be a direct child of FlexRow.
    #
    # AlertBanner is a block-level component designed to span full width. Placing it
    # inside a FlexRow collapses it to the width of a flex item, breaking its visual
    # treatment (colored background, border-radius, full-width icon + text layout).
    #
    # Use FlexColumn to stack AlertBanner with other content, or place it directly
    # as a sibling of FlexRow elements.
    #
    # @example Bad
    #   FlexRow(gap: :md, align: :center) do
    #     Icon(name: "info-circle-fill")
    #     AlertBanner(icon: "exclamation-triangle-fill", title: t("warning"), variant: :warning)
    #   end
    #
    # @example Good
    #   FlexColumn(gap: :md) do
    #     AlertBanner(icon: "exclamation-triangle-fill", title: t("warning"), variant: :warning)
    #     FlexRow(gap: :md) { ... }
    #   end
    class AlertBannerInFlexRow < Rule
      category "Structure"

      MESSAGE = "AlertBanner must not be a direct child of FlexRow. AlertBanner is block-level and " \
                "loses its full-width styling when collapsed to a flex item. Use FlexColumn instead."

      def check(tree)
        tree.each_node(:FlexRow) do |node|
          node.direct_children_named(:AlertBanner).each do |banner|
            violation(banner, MESSAGE)
          end
        end
      end
    end
  end
end
