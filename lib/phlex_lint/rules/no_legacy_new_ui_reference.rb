# frozen_string_literal: true

module PhlexLint
  module Rules
    # Use GlassMorph/glass_morph instead of legacy NewUi/new_ui naming.
    #
    # Components using the old NewUi namespace are deprecated. All components
    # must use the GlassMorph/glass_morph naming convention.
    #
    # @example Bad
    #   NewUiCard(title: "Settings")
    #   render NewUiButton.new(text: "Save")
    #   SomeComponent(class: "new-ui-card")
    #
    # @example Good
    #   GlassCard(title: "Settings")
    #   Button(text: "Save", variant: :primary)
    class NoLegacyNewUiReference < Rule
      category "Architecture"

      MESSAGE = "Use GlassMorph/glass_morph instead of legacy NewUi/new_ui naming."

      def check(tree)
        tree.each_node do |node|
          if node.name.to_s.match?(/NewUi|new_ui/)
            violation(node, MESSAGE)
            next
          end

          class_val = node.kwarg(:class)
          if class_val.is_a?(String) && class_val.match?(/\bnew[_-]ui\b/i)
            violation(node, MESSAGE)
          end
        end
      end
    end
  end
end
