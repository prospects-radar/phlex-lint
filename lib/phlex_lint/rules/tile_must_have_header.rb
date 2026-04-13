# frozen_string_literal: true

module PhlexLint
  module Rules
    # Every Tile block must contain a TileHeader as a direct child.
    #
    # Tile is a pure outer shell — it renders no header of its own.
    # Without an explicit TileHeader child the tile will have no gradient band
    # and will look broken in every variant.
    #
    # @example Bad
    #   Tile(variant: :banded) do
    #     Box(class: "gm-tile-body") { content }
    #   end
    #
    # @example Good
    #   Tile(variant: :banded) do
    #     TileHeader(variant: :banded, title: "Open Tasks")
    #     Box(class: "gm-tile-body") { content }
    #   end
    class TileMustHaveHeader < Rule
      category "Structure"

      MESSAGE = "Tile must contain a TileHeader as a direct child. " \
                "Compose the header explicitly: TileHeader(variant:, title:, ...)."

      def check(tree)
        tree.each_node(:Tile) do |node|
          next if node.direct_children_named(:TileHeader).any?

          violation(node, MESSAGE)
        end
      end
    end
  end
end
