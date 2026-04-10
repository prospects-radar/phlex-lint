# frozen_string_literal: true

module PhlexLint
  module Rules
    # LightTile must not directly wrap StatCard or DataCard.
    #
    # StatCard and DataCard already provide their own tile-level visual treatment
    # (border, padding, optional hover). Wrapping them in LightTile adds a second
    # unnecessary border/padding layer, resulting in double-framed cards.
    #
    # LightTile is intended for custom content that needs a subtle tile frame —
    # not for components that are already tiles.
    #
    # @example Bad
    #   LightTile(padding: :md) do
    #     StatCard(label: t("stats.connections"), value: "42", variant: :info)
    #   end
    #
    # @example Good
    #   StatCard(label: t("stats.connections"), value: "42", variant: :info)
    class LightTileWrapsStatCard < Rule
      category "Substitution"

      WRAPPED_COMPONENTS = %i[StatCard DataCard].freeze
      MESSAGE = "LightTile must not directly wrap %<wrapped>s. %<wrapped>s already provides its own " \
                "tile visual treatment (border, padding). Remove the LightTile wrapper."

      def check(tree)
        tree.each_node(:LightTile) do |node|
          WRAPPED_COMPONENTS.each do |component_name|
            node.direct_children_named(component_name).each do |_child|
              violation(node, format(MESSAGE, wrapped: component_name))
            end
          end
        end
      end
    end
  end
end
