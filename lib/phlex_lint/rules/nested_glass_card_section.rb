# frozen_string_literal: true

module PhlexLint
  module Rules
    # GlassCard(variant: :section) must not be nested inside another GlassCard.
    #
    # Section cards are top-level page sections — children of PageContainer.
    # Nesting a section card inside another glass card creates double-header
    # visual confusion and breaks the page information hierarchy.
    #
    # If sub-sections are needed inside a card, use GlassCard(variant: :glass)
    # or GlassPanel for the inner container.
    #
    # @example Bad
    #   GlassCard(variant: :section, title: t("outer"), icon: "gear", row_wrapper: false) do
    #     GlassCard(variant: :section, title: t("inner"), icon: "info-circle-fill", row_wrapper: false) do
    #       ...
    #     end
    #   end
    #
    # @example Good — use :glass for inner cards
    #   GlassCard(variant: :section, title: t("section"), icon: "gear", row_wrapper: false) do
    #     GlassCard(variant: :glass) do
    #       ...
    #     end
    #   end
    class NestedGlassCardSection < Rule
      category "Structure"

      MESSAGE = "GlassCard(variant: :section) must not be nested inside another GlassCard. " \
                "Section cards are top-level page sections (direct children of PageContainer). " \
                "Use GlassCard(variant: :glass) for inner cards."

      def check(tree)
        tree.each_node(:GlassCard) do |node|
          next unless node.kwarg(:variant) == :section
          next unless node.ancestor?(:GlassCard)

          violation(node, MESSAGE)
        end
      end
    end
  end
end
