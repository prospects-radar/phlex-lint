# frozen_string_literal: true

module PhlexLint
  module Rules
    # Raw <small> HTML elements should use the Text atom instead.
    #
    # The Text atom renders a native <small> tag via level: :small, so there
    # is no reason to bypass it. Using the atom gives access to color:, weight:,
    # and size: parameters consistently with the rest of the design system.
    #
    # @example Bad
    #   small { "Helper text" }
    #   small(class: "gm-text-muted fw-medium") { "Caption" }
    #
    # @example Good
    #   Text(level: :small) { "Helper text" }
    #   Text(level: :small, color: :muted, weight: :medium) { "Caption" }
    class NoSmallElement < Rule
      category "DesignSystem"

      MESSAGE = "Use Text(level: :small, ...) instead of raw <small>. " \
                "The Text atom renders <small> natively and exposes color: and weight: parameters."

      def check(tree)
        tree.each_node(:small) do |node|
          violation(node, MESSAGE)
        end
      end
    end
  end
end
