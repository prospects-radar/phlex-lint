# frozen_string_literal: true

module PhlexLint
  module Rules
    # Detect raw button/a elements with Bootstrap btn class.
    #
    # Raw `button(class: "btn ...")` and `a(class: "btn ...")` elements bypass
    # the design system Button and Link components, losing variant enforcement,
    # accessibility attributes, and consistent styling.
    #
    # @example Bad
    #   button(class: "btn btn-primary") { "Save" }
    #   a(href: "/path", class: "btn btn-secondary") { "Cancel" }
    #
    # @example Good
    #   Button(text: "Save", variant: :primary)
    #   Link(href: "/path", text: "Cancel")
    class NoRawButtons < Rule
      category "DesignSystem"

      MESSAGE = "Use Button() or Link() component instead of raw button/a element with btn class."

      def check(tree)
        %i[button a].each do |tag|
          tree.each_node(tag) do |node|
            class_val = node.kwarg(:class)
            next unless class_val.is_a?(String)
            next unless class_val.match?(/\bbtn\b/)

            violation(node, MESSAGE)
          end
        end
      end
    end
  end
end
