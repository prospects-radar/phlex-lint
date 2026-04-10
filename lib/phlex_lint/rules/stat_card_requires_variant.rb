# frozen_string_literal: true

module PhlexLint
  module Rules
    # StatCard must have an explicit variant: kwarg.
    #
    # StatCard defaults to variant: :default (slate/neutral) when not specified.
    # Each stat card should communicate its semantic meaning through color:
    # :success (green), :danger (red), :warning (amber), :info (blue), :purple.
    # Omitting variant produces an unlabelled gray card that conveys no meaning.
    #
    # @example Bad
    #   StatCard(label: t("stats.connections"), value: "42", icon: "people")
    #
    # @example Good
    #   StatCard(label: t("stats.connections"), value: "42", icon: "people", variant: :info)
    class StatCardRequiresVariant < Rule
      category "ComponentAPI"

      MESSAGE = "StatCard must have an explicit variant: kwarg (:success, :danger, :warning, :info, or :purple). " \
                "Omitting it produces a neutral gray card with no semantic color meaning."

      protected

      def auto_correct(node, _message)
        variant = infer_stat_card_variant(node)

        AddKwargCorrection.new(
          file_path: @file_path,
          line: node.source_node&.loc&.line || 0,
          column: node.source_node&.loc&.column || 0,
          kwarg_key: :variant,
          kwarg_value: variant,
          description: "Add variant: #{variant}"
        )
      end

      private

      def infer_stat_card_variant(node)
        # Extract label from the stat card
        label = extract_label(node)
        return :info unless label

        label_lower = label.downcase

        # Negative/error states
        if label_lower.match?(/error|fail|failed|issue|problem|down|offline|inactive/)
          return :danger
        end

        # Warning states
        if label_lower.match?(/warning|alert|at risk|pending|review/)
          return :warning
        end

        # Success states
        if label_lower.match?(/success|active|complete|online|resolved|healthy/)
          return :success
        end

        # Special state: purple for unique/featured metrics
        if label_lower.match?(/score|rating|index|ai|opportunit|potential/)
          return :purple
        end

        # Default to info for metrics
        :info
      end

      def extract_label(node)
        # Try to get the label: kwarg value
        label_kwarg = node.kwargs[:label]
        return label_kwarg if label_kwarg.is_a?(String)

        nil
      end

      public

      def check(tree)
        tree.each_node(:StatCard) do |node|
          next if node.kwargs.key?(:variant)

          violation(node, MESSAGE)
        end
      end
    end
  end
end
