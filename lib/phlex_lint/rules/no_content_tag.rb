# frozen_string_literal: true

module PhlexLint
  module Rules
    # Detect use of Rails content_tag in Phlex components.
    #
    # Phlex provides its own element methods (div, span, button, etc.) which
    # are tracked by the linter. Using content_tag bypasses the linter's
    # structural analysis and design system validation.
    #
    # @example Bad
    #   content_tag(:div, class: "d-flex") { ... }
    #   content_tag(:button, "Submit", class: "btn btn-primary")
    #
    # @example Good
    #   div(class: "d-flex") { ... }
    #   Button(text: "Submit", variant: :primary)
    class NoContentTag < Rule
      category "Lint"

      MESSAGE = "Use Phlex element methods (div, span, button, etc.) instead of content_tag. " \
                "content_tag bypasses linter analysis and design system validation."

      def check(tree)
        tree.each_node do |node|
          next unless node.name == :content_tag

          violation(node, MESSAGE)
        end
      end
    end
  end
end
