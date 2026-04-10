# frozen_string_literal: true

module PhlexLint
  module Rules
    # Icon name must be from the approved design system icon set.
    #
    # The design system provides 45 approved icons for consistency.
    # Using unapproved icon names (typos, custom icons) breaks the design system.
    #
    # @example Bad
    #   Icon(name: "unicorn")  # Not in approved set
    #   Icon(name: "trash-can")  # Should be "trash"
    #
    # @example Good
    #   Icon(name: "trash")
    #   Icon(name: "search")
    class IconMustBeApproved < Rule
      category "DesignSystem"

      # Approved 45-icon set from design system
      APPROVED_ICONS = Set.new(%w[
        activity arrow-left arrow-right arrow-right-circle bar-chart-line box
        box-arrow-up-right briefcase broadcast building building-check buildings
        bullseye calendar calendar-check calendar-event check-circle-fill chevron-down
        chevron-right circle-fill clipboard clock download envelope envelope-open
        exclamation-triangle-fill eye file-earmark-text funnel gear globe graph-up-arrow
        grid-3x3 heart-pulse home inbox infinity info-circle-fill key lightning-charge
        linkedin lock newspaper pencil people person pie-chart plus-lg question-circle
        reply robot search send shield-check speedometer2 star-fill stars tags telephone
        three-dots-vertical trash x-circle-fill
      ]).freeze

      MESSAGE = "Icon name '%<name>s' not in approved design system set. " \
                "Use one of the 45 approved icons. See design-system skill for full list."

      def check(tree)
        tree.each_node(:Icon) do |node|
          icon_name = node.kwarg(:name)
          next unless icon_name
          next if icon_name == :__dynamic__ || icon_name == :__interpolated__  # Dynamic/interpolated values, can't validate
          next if APPROVED_ICONS.include?(icon_name)

          violation(node, format(MESSAGE, name: icon_name))
        end
      end
    end
  end
end
