# frozen_string_literal: true

module PhlexLint
  module Rules
    # GlassCard variant must be one of the approved design system values.
    #
    # Using an unknown variant results in unstyled or broken card rendering.
    # Only :glass, :solid, :section, and :elevated are valid.
    #
    # @example Bad
    #   GlassCard(variant: :primary)
    #   GlassCard(variant: :dark)
    #
    # @example Good
    #   GlassCard(variant: :glass)
    #   GlassCard(variant: :solid)
    class GlassCardVariant < Rule
      category "ComponentAPI"

      MESSAGE = "GlassCard variant must be one of: :glass, :solid, :section, :elevated. Got: %<actual>s"

      VALID_VALUES = %i[glass solid section elevated].freeze

      def check(tree)
        tree.each_node(:GlassCard) do |node|
          next unless node.kwargs.key?(:variant)

          value = node.kwarg(:variant)
          next if value == :__dynamic__ || value == :__interpolated__
          next if VALID_VALUES.include?(value)

          violation(node, format(MESSAGE, actual: value.inspect))
        end
      end
    end
  end
end
