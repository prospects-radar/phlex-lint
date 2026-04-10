# frozen_string_literal: true

module PhlexLint
  module Rules
    # FormSectionHeader must not appear inside a GlassCard(variant: :section).
    #
    # GlassCard(variant: :section, title:, icon:) already renders a teal header.
    # Adding FormSectionHeader inside creates a duplicate visual header and defeats
    # the purpose of using the section variant.
    #
    # Instead, use GlassCard(variant: :section, title:, icon:) for the outer section
    # and FormSectionHeader only inside GlassCard(variant: :glass) for sub-sections.
    #
    # @example Bad
    #   GlassCard(variant: :section, title: t("section.title"), icon: "gear", row_wrapper: false) do
    #     FormSectionHeader(title: t("sub.title"))  # redundant — card already has a title
    #     FlexColumn(gap: :md) { ... }
    #   end
    #
    # @example Good
    #   GlassCard(variant: :glass) do
    #     FormSectionHeader(title: t("sub.title"))
    #     FlexColumn(gap: :md) { ... }
    #   end
    class FormSectionHeaderInGlassCardSection < Rule
      category "Substitution"

      MESSAGE = "FormSectionHeader inside GlassCard(variant: :section) creates a duplicate header. " \
                "The section card already renders a header via title: and icon:. " \
                "Use GlassCard(variant: :glass) if you need a headerless card with an internal FormSectionHeader."

      def check(tree)
        tree.each_node(:FormSectionHeader) do |node|
          next unless node.any_ancestor? { |a| a.name == :GlassCard && a.kwarg(:variant) == :section }

          violation(node, MESSAGE)
        end
      end
    end
  end
end
