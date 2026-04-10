# frozen_string_literal: true

module PhlexLint
  module Rules
    # Modal must have an explicit size: kwarg.
    #
    # Modal size controls the modal's width and padding. Without it, the modal
    # renders at an undefined size that may not work for the content.
    #
    # @example Bad
    #   Modal(id: "confirm", title: "Delete?")
    #
    # @example Good
    #   Modal(id: "confirm", title: "Delete?", size: :md)
    class ModalRequiresSize < Rule
      category "ComponentAPI"

      MESSAGE = "Modal must have an explicit size: kwarg (:sm, :md, or :lg). " \
                "Omitting it produces an undefined modal size."

      protected

      def auto_correct(node, _message)
        # Default to :md; developers can adjust if needed
        AddKwargCorrection.new(
          file_path: @file_path,
          line: node.source_node&.loc&.line || 0,
          column: node.source_node&.loc&.column || 0,
          kwarg_key: :size,
          kwarg_value: :md,
          description: "Add size: :md (adjust if needed)"
        )
      end

      public

      def check(tree)
        tree.each_node(:Modal) do |node|
          next if node.kwargs.key?(:size)

          violation(node, MESSAGE)
        end
      end
    end
  end
end
