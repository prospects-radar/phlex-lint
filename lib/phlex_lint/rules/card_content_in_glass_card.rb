# frozen_string_literal: true

module PhlexLint
  module Rules
    # Flags CardContent used as a direct child of GlassCard.
    #
    # This is the anti-pattern where developers manually build section headers
    # instead of using GlassCard(variant: :section, icon:, title:, row_wrapper: false),
    # which provides the header and correct padding automatically.
    #
    # @example Bad — manual section header
    #   GlassCard(padding: :md) do
    #     CardContent do
    #       CardHeader(title: "Section Title", icon: "info-circle-fill")
    #       FlexColumn(gap: :md) { ... }
    #     end
    #   end
    #
    # @example Good — declarative section card
    #   GlassCard(variant: :section, icon: "info-circle-fill", title: t("..."), row_wrapper: false) do
    #     FlexColumn(gap: :md) { ... }
    #   end
    class CardContentInGlassCard < Rule
      category "Substitution"

      MESSAGE = "Avoid CardContent inside GlassCard. Use GlassCard(variant: :section, " \
                'icon: "...", title: t("..."), row_wrapper: false) which provides the section header automatically.'

      def self.documentation_url
        ".claude/skills/design-system/SKILL.md#component-decision-tree"
      end

      def check(tree)
        tree.each_node(:GlassCard) do |glass_card_node|
          glass_card_node.direct_children_named(:CardContent).each do |card_content_node|
            violation(card_content_node, MESSAGE)
          end
        end
      end
    end
  end
end
