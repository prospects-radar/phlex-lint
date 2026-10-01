# frozen_string_literal: true

module PhlexLint
  module Rules
    # `color: :muted_dark` is deprecated on Span, Text, and Paragraph atoms.
    #
    # The `:muted_dark` color token was consolidated into the `tone:` API.
    # Use `tone: :dark` to achieve the same dark-surface muted text style.
    #
    # @example Bad
    #   Span(color: :muted_dark) { label }
    #   Text(content: body, color: :muted_dark)
    #   Paragraph(text: note, color: :muted_dark, size: :sm)
    #
    # @example Good
    #   Span(tone: :dark) { label }
    #   Text(content: body, tone: :dark)
    #   Paragraph(text: note, tone: :dark, size: :sm)
    class NoDeprecatedMutedDarkColor < Rule
      category "DesignSystem"

      AFFECTED_COMPONENTS = %i[Span Text Paragraph].freeze

      MESSAGE = "`color: :muted_dark` is deprecated on %<component>s. Use `tone: :dark` instead."

      def check(tree)
        AFFECTED_COMPONENTS.each do |component|
          tree.each_node(component) do |node|
            next unless node.kwarg(:color) == :muted_dark

            violation(node, format(MESSAGE, component: component))
          end
        end
      end
    end
  end
end
