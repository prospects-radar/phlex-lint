# frozen_string_literal: true

module PhlexLint
  module Rules
    # Detect raw span/div elements with Bootstrap badge class.
    #
    # Raw `span(class: "badge ...")` and `div(class: "badge ...")` elements
    # bypass the design system Badge component, which enforces proper semantic
    # variants (status, count, score) and consistent visual treatment.
    #
    # @example Bad
    #   span(class: "badge bg-success") { "Active" }
    #   div(class: "badge badge-pill") { "3" }
    #
    # @example Good
    #   Badge.status(status: :success, label: "Active")
    #   Badge.count(count: 3)
    class NoRawBadgeSpans < Rule
      category "DesignSystem"

      MESSAGE = "Use Badge.status(), Badge.count(), or Badge.score() instead of raw span/div with badge class."

      def check(tree)
        %i[span div].each do |tag|
          tree.each_node(tag) do |node|
            class_val = node.kwarg(:class)
            next unless class_val.is_a?(String)
            next unless class_val.match?(/\bbadge\b/)

            violation(node, MESSAGE)
          end
        end
      end
    end
  end
end
