# frozen_string_literal: true

module PhlexLint
  module Rules
    # Avoid inline style: attributes on any node.
    #
    # Inline styles bypass the design token system, cannot be overridden by themes,
    # and create maintenance burden. Extract to CSS classes or use existing gm-* tokens.
    #
    # @example Bad
    #   div(style: "margin-top: 16px; color: #333")
    #   span(style: "font-weight: bold")
    #
    # @example Good
    #   div(class: "gm-mt-4 gm-text-primary")
    #   span(class: "fw-bold")
    class NoInlineStyles < Rule
      category "Style"

      MESSAGE = "Avoid inline style: attributes. Use CSS classes or design tokens in stylesheets."

      # File exclusions (mailers, debug components) are configured in .phlex-lint.yml.

      def check(tree)
        tree.each_node do |node|
          style_val = node.kwarg(:style)
          next unless style_val.is_a?(String)

          violation(node, MESSAGE)
        end
      end
    end
  end
end
