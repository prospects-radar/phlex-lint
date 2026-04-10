# frozen_string_literal: true

module PhlexLint
  module Rules
    # Detect raw Bootstrap Icon class usage (bi bi-*).
    #
    # Raw Bootstrap Icon classes should be replaced with the Icon() component,
    # which enforces the approved icon set and provides consistent sizing/styling.
    #
    # @example Bad
    #   span(class: "bi bi-house")
    #   i(class: "bi bi-arrow-right me-2")
    #
    # @example Good
    #   Icon(name: "house")
    #   Icon(name: "arrow-right")
    class NoRawBiIconClasses < Rule
      category "Style"

      PATTERN = /\bbi\s+bi-/.freeze
      MESSAGE = 'Use Icon(name: "icon-name") instead of raw Bootstrap Icon classes (bi bi-*).'

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
