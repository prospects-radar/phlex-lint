# frozen_string_literal: true

module PhlexLint
  module Rules
    # Detect Tailwind CSS utility classes in GlassMorph components.
    #
    # This project uses Bootstrap 5 and the gm-* design token system.
    # Tailwind utility classes are not part of the design system and should
    # not be introduced. Use Bootstrap 5 equivalents or gm-* tokens instead.
    #
    # @example Bad
    #   div(class: "flex items-center justify-between")
    #   span(class: "text-gray-500 hover:text-gray-700")
    #
    # @example Good
    #   FlexRow(gap: :md)
    #   span(class: "gm-text-muted")
    class NoNewTailwindUsage < Rule
      category "Style"

      # Tailwind classes that must match as whole tokens (no substring matching).
      # This prevents Bootstrap classes like "align-items-center" from falsely triggering "items-center".
      TAILWIND_TOKEN_PATTERN = /\A(
        items-(?:center|start|end|stretch|baseline)|
        justify-(?:between|center|start|end|around|evenly)|
        flex-(?:col|row|wrap|nowrap|1|auto|none|grow|shrink)|
        gap-\d+|
        text-(?:gray|slate|zinc|neutral|stone)-\d{3}|
        bg-(?:gray|slate|zinc|neutral|stone)-\d{3}|
        rounded-(?:full|lg|md|sm|xl|2xl|3xl|none)|
        grid-cols-\d+|col-span-\d+|
        space-[xy]-\d+|
        w-full|w-screen|h-full|h-screen|min-h-screen|
        max-w-(?:sm|md|lg|xl|2xl|3xl|4xl|5xl|6xl|7xl|full|screen|none|xs)|
        overflow-(?:hidden|auto|scroll|visible)|
        cursor-pointer|pointer-events-none|
        opacity-\d+|
        transition(?:-\w+)?|duration-\d+|ease-\w+|
        hover:.+|focus:.+|active:.+
      )\z/x.freeze

      MESSAGE = "Tailwind CSS class detected. Use Bootstrap 5 classes in GlassMorph components."

      def check(tree)
        tree.each_node do |node|
          class_val = node.kwarg(:class)
          next unless class_val.is_a?(String)

          tokens = class_val.split
          next unless tokens.any? { |t| t.match?(TAILWIND_TOKEN_PATTERN) }

          violation(node, MESSAGE)
        end
      end
    end
  end
end
