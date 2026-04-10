# frozen_string_literal: true

module PhlexLint
  module Rules
    # Use class: instead of deprecated css_class: parameter.
    #
    # The css_class: parameter is a legacy non-standard API. All components
    # accept the standard class: keyword argument instead.
    #
    # @example Bad
    #   Button(text: "Save", css_class: "mt-2")
    #   GlassCard(css_class: "mb-4")
    #
    # @example Good
    #   Button(text: "Save", class: "mt-2")
    #   GlassCard(class: "mb-4")
    class ClassParameter < Rule
      category "ComponentAPI"

      MESSAGE = "Use class: instead of deprecated css_class: parameter — standard API convention."

      def check(tree)
        tree.each_node do |node|
          next unless node.kwargs.key?(:css_class)

          violation(node, MESSAGE)
        end
      end
    end
  end
end
