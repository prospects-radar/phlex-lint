# frozen_string_literal: true

module PhlexLint
  module Rules
    # Inline content components should not carry margin utilities; use the parent's gap: instead.
    #
    # Adding margin utilities to leaf components like Heading, Badge, or Button creates
    # fragile spacing that breaks when the component is reused in different contexts.
    # The parent FlexRow or FlexColumn should control spacing through its gap: parameter.
    #
    # @example Bad
    #   Heading(class: "mb-3", level: 2)
    #   Badge.status(status: :success, class: "mt-2")
    #
    # @example Good
    #   FlexColumn(gap: :md) do
    #     Heading(level: 2)
    #     Badge.status(status: :success)
    #   end
    class UseParentGapForSpacing < Rule
      category "Style"

      INLINE_COMPONENTS = %i[Heading Paragraph Text Span Badge Button Icon StatCard ScoreBadge Separator].freeze

      # Atoms define their own internals and are allowed to use margin utilities
      # on sub-components for precise internal layout. Only enforce in molecules, organisms, views.
      def self.applies_to_file?(file_path)
        !file_path.include?("/atoms/")
      end
      MARGIN_PATTERN = /\bm[tbes]?-\d+\b/.freeze
      MESSAGE = "Use the parent's gap: parameter instead of margin utilities on %<component>s components."

      def check(tree)
        INLINE_COMPONENTS.each do |component_name|
          tree.each_node(component_name) do |node|
            class_val = node.kwarg(:class)
            next unless class_val.is_a?(String)
            next unless class_val.match?(MARGIN_PATTERN)

            violation(node, format(MESSAGE, component: node.name))
          end
        end
      end
    end
  end
end
