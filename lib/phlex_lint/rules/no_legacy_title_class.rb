# frozen_string_literal: true

module PhlexLint
  module Rules
    # Heading() must not use deprecated page-title CSS classes.
    #
    # Custom title classes (`prospects-title`, `pricing-title`, `value-hero-title`)
    # were consolidated into the single `hero-title` token. Using the old classes
    # produces inconsistent typography across pages.
    #
    # @example Bad
    #   Heading(level: 1, class: "prospects-title") { @title }
    #   Heading(level: 1, class: "pricing-title") { t(".title") }
    #   Heading(level: 1, class: "value-hero-title") { t("dashboard.title") }
    #
    # @example Good
    #   Heading(level: 1, class: "hero-title") { @title }
    class NoLegacyTitleClass < Rule
      category "DesignSystem"

      DEPRECATED_CLASSES = %w[
        prospects-title
        pricing-title
        value-hero-title
        value-section-title
        analytics-chart-title
      ].freeze

      MESSAGE = "Replace deprecated title class `%<klass>s` with `hero-title` on Heading()."

      def check(tree)
        tree.each_node(:Heading) do |node|
          class_val = node.kwarg(:class)
          next unless class_val.is_a?(String)

          DEPRECATED_CLASSES.each do |deprecated|
            next unless class_val.split.include?(deprecated)

            violation(node, format(MESSAGE, klass: deprecated))
          end
        end
      end
    end
  end
end
