# frozen_string_literal: true

module PhlexLint
  module Rules
    # Badge should not receive non-layout CSS classes.
    #
    # Badge styling is fully managed by its builder methods (type:, color:, variant:).
    # Passing arbitrary CSS classes bypasses the design system and causes
    # inconsistent styling. Only layout-positioning classes (m-*, p-*, gap-*) are allowed.
    #
    # @example Bad
    #   Badge(type: :status, label: "Active", class: "text-success fw-bold")
    #   Badge(type: :count, count: 5, class: "badge-custom")
    #
    # @example Good
    #   Badge(type: :status, label: "Active")
    #   Badge(type: :status, label: "Active", class: "mt-2 mb-1")
    class NoClassOnBadge < Rule
      category "ComponentAPI"

      MESSAGE = "Encapsulate styling in Badge builder methods. " \
                "Only layout-positioning classes (m-*, p-*, gap-*) are allowed on Badge."

      LAYOUT_ONLY_PATTERN = /\A([ ]*(m[tblrxy]?-\d+|p[tblrxy]?-\d+|gap-\d+))+\s*\z/

      def check(tree)
        tree.each_node(:Badge) do |node|
          next unless node.kwargs.key?(:class)

          class_val = node.kwarg(:class)
          next if class_val == :__dynamic__ || class_val == :__interpolated__
          next unless class_val.is_a?(String)
          next if class_val.strip.empty?
          next if LAYOUT_ONLY_PATTERN.match?(class_val)

          violation(node, MESSAGE)
        end
      end
    end
  end
end
