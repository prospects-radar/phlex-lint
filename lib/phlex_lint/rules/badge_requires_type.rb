# frozen_string_literal: true

module PhlexLint
  module Rules
    # Badge must have an explicit type: kwarg.
    #
    # Badge is used in multiple contexts (:status, :count, :score) with different
    # styling. Omitting type: produces ambiguous styling that may not fit the context.
    #
    # @example Bad
    #   Badge(label: "Active")
    #   Badge(count: 5)
    #
    # @example Good
    #   Badge(type: :status, label: "Active")
    #   Badge(type: :count, count: 5)
    class BadgeRequiresType < Rule
      category "ComponentAPI"

      MESSAGE = "Badge must have an explicit type: kwarg (:status, :count, or :score). " \
                "Omitting it produces ambiguous styling."

      protected

      def auto_correct(node, _message)
        # Infer from context if possible
        type = infer_badge_type(node)

        AddKwargCorrection.new(
          file_path: @file_path,
          line: node.source_node&.loc&.line || 0,
          column: node.source_node&.loc&.column || 0,
          kwarg_key: :type,
          kwarg_value: type,
          description: "Add type: #{type}"
        )
      end

      public

      def check(tree)
        tree.each_node(:Badge) do |node|
          next if node.kwargs.key?(:type)

          violation(node, MESSAGE)
        end
      end

      private

      def infer_badge_type(node)
        # :count if has count: kwarg
        return :count if node.kwargs.key?(:count)

        # :score if has score: kwarg
        return :score if node.kwargs.key?(:score)

        # :status for everything else (most common)
        :status
      end
    end
  end
end
