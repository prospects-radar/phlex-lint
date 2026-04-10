# frozen_string_literal: true

module PhlexLint
  module Rules
    # Avoid hardcoded spacing values. Use design system spacing tokens or flex gap instead.
    #
    # Hardcoded px/rem values (style: "margin: 16px", style: "padding: 0.5rem") break
    # responsive design and create maintenance burden. Use gap:, padding: with tokens, or CSS classes.
    #
    # This rule detects inline styles with spacing keywords and flags them.
    #
    # @example Bad
    #   div(style: "margin: 16px; padding: 8px")
    #   div(class: "mb-3")  # Bootstrap class
    #
    # @example Good
    #   FlexColumn(gap: :md)
    #   div(class: "gm-mt-4")  # Design system token
    class NoHardcodedSpacing < Rule
      category "Style"

      BOOTSTRAP_SPACING_PATTERN = /\b(m[tblrxy]?-\d+|p[tblrxy]?-\d+)\b/.freeze

      # Layout containers are allowed to use Bootstrap spacing for positioning
      LAYOUT_CONTAINERS = Set.new(%i[Box FlexRow FlexColumn GlassCard PageContainer Section]).freeze

      # These are covered by UseParentGapForSpacing and NoExtraClassesOnStandardizedComponents
      # with better, more specific messages. Skip them here to avoid triple-counting.
      COVERED_BY_OTHER_RULES = Set.new(%i[
        Heading Paragraph Text Span Badge Button Icon StatCard Separator
      ]).freeze

      MESSAGE = "Use design system spacing tokens (gap: :md on parent FlexRow/FlexColumn) " \
                "instead of Bootstrap spacing utilities. Found: %<classes>s"

      def check(tree)
        tree.each_node do |node|
          next if LAYOUT_CONTAINERS.include?(node.name)
          next if COVERED_BY_OTHER_RULES.include?(node.name)

          class_val = node.kwarg(:class)
          next if class_val.nil?
          next if class_val == :__dynamic__ || class_val == :__interpolated__
          next unless class_val.is_a?(String)
          next unless class_val.match?(BOOTSTRAP_SPACING_PATTERN)

          violation(node, format(MESSAGE, classes: class_val))
        end
      end
    end
  end
end
