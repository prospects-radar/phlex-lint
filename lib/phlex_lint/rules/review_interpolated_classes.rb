# frozen_string_literal: true

module PhlexLint
  module Rules
    # Flag interpolated class strings for manual review.
    #
    # When class strings use interpolation (class: "btn #{variant}"), the linter
    # cannot validate the result at lint time. These should be reviewed to ensure
    # they produce valid design system classes.
    #
    # @example Needs Review
    #   Button(class: "btn btn-#{variant}") { "Save" }
    #   div(class: "#{type}-card") { ... }
    #
    # @example Better (if possible)
    #   Button(text: "Save", variant: variant)
    #   div(class: "status-card") { ... }
    class ReviewInterpolatedClasses < Rule
      category "Lint"

      MESSAGE = "Class string uses interpolation. Review to ensure it produces valid design system classes. " \
                "Consider using component parameters instead of building classes dynamically."

      def check(tree)
        tree.each_node do |node|
          class_val = node.kwarg(:class)
          next unless class_val == :__interpolated__

          violation(node, MESSAGE)
        end
      end
    end
  end
end
