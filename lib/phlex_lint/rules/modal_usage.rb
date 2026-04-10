# frozen_string_literal: true

module PhlexLint
  module Rules
    # Detect hand-rolled Bootstrap modal markup and require component usage instead.
    #
    # Raw Bootstrap modal classes (modal, modal-dialog, modal-content) create brittle
    # markup that is hard to maintain and lacks the accessibility defaults provided
    # by the design system modal components.
    #
    # @example Bad
    #   div(class: "modal fade", id: "myModal") do
    #     div(class: "modal-dialog") do
    #       div(class: "modal-content")
    #     end
    #   end
    #
    # @example Good
    #   Modal(id: "my-modal", title: "Confirm Action") do
    #     ...
    #   end
    class ModalUsage < Rule
      category "Style"

      PATTERN = /\bmodal\b.*\b(fade|modal-dialog|modal-content)\b|\b(modal-dialog|modal-content)\b/.freeze
      MESSAGE = "Use Modal(), TurboModal(), ConfirmationModal(), or DangerModal() components instead of Bootstrap modal classes."

      def check(tree)
        tree.each_node do |node|
          class_val = node.kwarg(:class)
          next unless class_val.is_a?(String)
          next unless class_val.match?(PATTERN)

          violation(node, MESSAGE)
        end
      end
    end
  end
end
