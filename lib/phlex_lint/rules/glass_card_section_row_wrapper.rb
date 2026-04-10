# frozen_string_literal: true

module PhlexLint
  module Rules
    # GlassCard(variant: :section) must always include row_wrapper: false.
    #
    # Without it, GlassCard wraps the block body in a Bootstrap .row > .col grid,
    # which breaks any custom layout (FlexColumn, StatCard grids, etc.) inside it.
    #
    # @example Bad
    #   GlassCard(variant: :section, icon: "info-circle-fill", title: t("...")) do
    #     FlexColumn(gap: :md) { ... }
    #   end
    #
    # @example Good
    #   GlassCard(variant: :section, icon: "info-circle-fill", title: t("..."), row_wrapper: false) do
    #     FlexColumn(gap: :md) { ... }
    #   end
    class GlassCardSectionRowWrapper < Rule
      category "ComponentAPI"

      MESSAGE = "GlassCard(variant: :section) must include `row_wrapper: false` to prevent automatic Bootstrap .row/.col wrapping."

      def self.documentation_url
        ".claude/skills/design-system/SKILL.md#component-decision-tree"
      end

      protected

      def auto_correct(node, _message)
        AddKwargCorrection.new(
          file_path: @file_path,
          line: node.source_node&.loc&.line || 0,
          column: node.source_node&.loc&.column || 0,
          kwarg_key: :row_wrapper,
          kwarg_value: false,
          description: "Add row_wrapper: false"
        )
      end

      public

      def check(tree)
        tree.each_node(:GlassCard) do |node|
          next unless node.kwarg(:variant) == :section
          next if node.kwarg(:row_wrapper) == false

          violation(node, MESSAGE)
        end
      end
    end
  end
end
