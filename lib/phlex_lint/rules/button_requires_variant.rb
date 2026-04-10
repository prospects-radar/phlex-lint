# frozen_string_literal: true

module PhlexLint
  module Rules
    # Button must always have an explicit variant: kwarg.
    #
    # Button defaults to variant: :default (unstyled) when no variant is provided.
    # Every button must be intentionally styled as :primary, :secondary, :tertiary,
    # or :danger — never relying on the invisible default.
    #
    # @example Bad
    #   Button(text: t("actions.save"))
    #   Button(text: t("actions.delete"), icon: "trash")
    #
    # @example Good
    #   Button(text: t("actions.save"), variant: :primary)
    #   Button(text: t("actions.delete"), variant: :danger, icon: "trash")
    class ButtonRequiresVariant < Rule
      category "ComponentAPI"

      MESSAGE = "Button must have an explicit variant: kwarg (:primary, :secondary, :tertiary, or :danger). " \
                "Omitting it silently uses :default (unstyled)."

      protected

      def auto_correct(node, _message)
        variant = infer_button_variant(node)

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

      def infer_button_variant(node)
        # Extract text from the button's text: kwarg or other content
        text_value = extract_text_content(node)
        return :primary unless text_value

        text_lower = text_value.downcase

        # Destructive actions
        if text_lower.match?(/delete|remove|destroy|discard/)
          return :danger
        end

        # Dismissive/secondary actions
        if text_lower.match?(/close|dismiss|cancel/)
          return :secondary
        end

        # Primary/constructive actions
        if text_lower.match?(/save|create|add|submit|update|confirm/)
          return :primary
        end

        # Neutral/informational
        if text_lower.match?(/learn|view|preview|download/)
          return :tertiary
        end

        # Default to primary for unknown
        :primary
      end

      def extract_text_content(node)
        # Try to get the text: kwarg value
        text_kwarg = node.kwargs[:text]
        return text_kwarg if text_kwarg.is_a?(String)

        # Try icon label if no text
        icon_kwarg = node.kwargs[:icon]
        return nil if icon_kwarg

        # If no explicit text/icon, can't infer
        nil
      end

      public

      def check(tree)
        tree.each_node(:Button) do |node|
          next if node.kwargs.key?(:variant)

          violation(node, MESSAGE)
        end
      end
    end
  end
end
