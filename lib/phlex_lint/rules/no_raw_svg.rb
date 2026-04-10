# frozen_string_literal: true

module PhlexLint
  module Rules
    # Detect any raw svg element outside of atoms.
    #
    # Inline SVG markup belongs only inside atom-level components. Any raw `svg`
    # call in a view or higher-level component should use the Icon() atom instead,
    # which manages sizing, accessibility labels, and the approved icon set.
    #
    # @example Bad
    #   svg(xmlns: "http://www.w3.org/2000/svg", class: "icon") do
    #     path(d: "...")
    #   end
    #
    # @example Good
    #   Icon(name: "check-circle-fill", size: :sm)
    class NoRawSvg < Rule
      category "DesignSystem"

      MESSAGE = "Use Icon() atom instead of raw svg — raw SVG belongs only in atoms."

      def check(tree)
        tree.each_node(:svg) do |node|
          violation(node, MESSAGE)
        end
      end
    end
  end
end
