# frozen_string_literal: true

module PhlexLint
  module Rules
    # Icon() components must not be nested inside Heading().
    #
    # Icons embedded in headings couple iconography to typography and complicate
    # responsive sizing. Place icons in a FlexRow alongside the Heading instead.
    #
    # @example Bad
    #   Heading(level: 1, class: "hero-title") do
    #     Icon(name: "graph-up-arrow", size: :md, color: :white)
    #     plain t("dashboard.title")
    #   end
    #
    # @example Good
    #   FlexRow(align: :center, gap: :sm) do
    #     Icon(name: "graph-up-arrow", size: :md, color: :white)
    #     Heading(level: 1, class: "hero-title") { t("dashboard.title") }
    #   end
    class NoIconInHeading < Rule
      category "DesignSystem"

      MESSAGE = "Icon() must not be nested inside Heading(). Place the Icon in a FlexRow alongside the Heading."

      def check(tree)
        tree.each_node(:Icon) do |node|
          next unless node.ancestor?(:Heading)

          violation(node, MESSAGE)
        end
      end
    end
  end
end
