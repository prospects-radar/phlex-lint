# frozen_string_literal: true

module PhlexLint
  module Rules
    # Standardized design system components must not receive Bootstrap utility classes.
    #
    # Components like Heading, Text, Button, Badge, and Icon expose explicit parameters
    # (color:, size:, variant:) that map to the design system tokens. Passing Bootstrap
    # utility classes overrides these and breaks theming consistency.
    #
    # @example Bad
    #   Heading(level: 2, class: "fw-bold mb-3") { "Title" }
    #   Text(class: "text-muted mt-2") { "Body" }
    #   Button(variant: :primary, class: "ms-3") { "Save" }
    #
    # @example Good
    #   Heading(level: 2, color: :primary) { "Title" }
    #   Text(color: :muted) { "Body" }
    #   Button(variant: :primary) { "Save" }
    class NoExtraClassesOnStandardizedComponents < Rule
      category "Architecture"

      STANDARDIZED_COMPONENTS = %i[Heading Paragraph Text Span Badge Button Icon StatCard].freeze

      # Atoms define their own internals and are allowed to use Bootstrap utilities
      # on sub-components. Only enforce this rule in molecules, organisms, and views.
      def self.applies_to_file?(file_path)
        !file_path.include?("/atoms/")
      end

      # Margin utilities (mt-*, mb-*, ms-*, me-*) are intentionally excluded here —
      # UseParentGapForSpacing covers those with more specific "use parent gap:" advice.
      # Padding utilities and font/sizing utilities remain because no other rule covers them
      # on standardized components.
      BOOTSTRAP_UTILITY_PATTERN = /\b(fw-\d+|fw-bold|fw-light|fs-\d+|text-(?:white|muted|dark|light)|pt-\d+|pb-\d+|ps-\d+|pe-\d+|w-\d+|h-\d+)\b/.freeze

      MESSAGE = "Remove Bootstrap utilities from %<component>s — use component parameters instead (color:, size:, etc.)."

      def check(tree)
        STANDARDIZED_COMPONENTS.each do |component|
          tree.each_node(component) do |node|
            class_val = node.kwarg(:class)
            next if class_val.nil?
            next if class_val == :__dynamic__ || class_val == :__interpolated__
            next unless class_val.is_a?(String)
            next unless class_val.match?(BOOTSTRAP_UTILITY_PATTERN)

            violation(node, format(MESSAGE, component: node.name))
          end
        end
      end
    end
  end
end
