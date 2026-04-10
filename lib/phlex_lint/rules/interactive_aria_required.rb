# frozen_string_literal: true

module PhlexLint
  module Rules
    # Icon-only interactive components must include aria_label: for accessibility.
    #
    # When a Button, Link, LinkButton, or IconButton has an icon: but no visible text:,
    # screen readers have nothing to announce. An aria_label: must be provided
    # so the component is accessible.
    #
    # @example Bad
    #   Button(icon: "trash", variant: :danger)
    #   IconButton(icon: "pencil")
    #
    # @example Good
    #   Button(icon: "trash", variant: :danger, aria_label: t("actions.delete"))
    #   Button(icon: "save", text: t("actions.save"), variant: :primary)
    class InteractiveAriaRequired < Rule
      category "ComponentAPI"

      MESSAGE = "Icon-only %<component>s must include aria_label: for screen reader accessibility."

      INTERACTIVE_COMPONENTS = %i[Button Link LinkButton IconButton].freeze

      def check(tree)
        INTERACTIVE_COMPONENTS.each do |component|
          tree.each_node(component) do |node|
            next unless node.kwargs.key?(:icon)
            next if node.kwargs.key?(:text)
            next if node.kwargs.key?(:aria_label)

            violation(node, format(MESSAGE, component: node.name))
          end
        end
      end
    end
  end
end
