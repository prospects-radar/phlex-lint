# frozen_string_literal: true

module PhlexLint
  module Rules
    # GlassCard(variant: :section) must have both icon: and title: kwargs.
    #
    # The section variant renders a teal-gradient header with an icon and title.
    # Without them the header bar is blank, which is both visually broken and
    # semantically meaningless (use GlassCard(variant: :glass) for headerless cards).
    #
    # @example Bad
    #   GlassCard(variant: :section, row_wrapper: false) do
    #     FlexColumn(gap: :md) { ... }
    #   end
    #
    # @example Good
    #   GlassCard(variant: :section, icon: "info-circle-fill", title: t("..."), row_wrapper: false) do
    #     FlexColumn(gap: :md) { ... }
    #   end
    class GlassCardSectionRequiresIconAndTitle < Rule
      category "ComponentAPI"

      MESSAGE = "GlassCard(variant: :section) must include both icon: and title:. " \
                "Missing: %<missing>s. Use GlassCard(variant: :glass) for headerless cards."

      def check(tree)
        tree.each_node(:GlassCard) do |node|
          next unless node.kwarg(:variant) == :section

          missing = []
          missing << "icon:" unless node.kwargs.key?(:icon)
          missing << "title:" unless node.kwargs.key?(:title)
          next if missing.empty?

          violation(node, format(MESSAGE, missing: missing.join(", ")))
        end
      end
    end
  end
end
