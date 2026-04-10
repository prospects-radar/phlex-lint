# frozen_string_literal: true

module PhlexLint
  module Rules
    # FlexRow and FlexColumn gap: must use design system tokens, not arbitrary sizes.
    #
    # Gap accepts :xs, :sm, :md, :lg, :xl which map to CSS variables.
    # Arbitrary pixel values or strings break consistency and hinder responsive design.
    #
    # @example Bad
    #   FlexRow(gap: "16px")
    #   FlexColumn(gap: 16)
    #
    # @example Good
    #   FlexRow(gap: :md)
    #   FlexColumn(gap: :lg)
    class GapValueValidation < Rule
      category "DesignSystem"

      VALID_GAPS = %i[none xs sm md lg xl].freeze

      MESSAGE = "gap: must use design tokens (:none, :xs, :sm, :md, :lg, :xl), not arbitrary values. " \
                "Got: %<actual>s"

      def check(tree)
        %i[FlexRow FlexColumn].each do |component_name|
          tree.each_node(component_name) do |node|
            gap = node.kwarg(:gap)
            next unless gap
            next if VALID_GAPS.include?(gap)
            next if gap == :__dynamic__ || gap == :__interpolated__  # Dynamic/interpolated values, can't validate

            violation(node, format(MESSAGE, actual: gap))
          end
        end
      end
    end
  end
end
