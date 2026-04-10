# frozen_string_literal: true

module PhlexLint
  module Rules
    # Raw HTML elements should not apply gm-text-* design token classes directly.
    #
    # These classes are the output of the Text atom's color: parameter.
    # Using them directly on raw HTML bypasses the design system component and
    # creates invisible coupling to internal CSS implementation details.
    #
    # @example Bad
    #   span(class: "gm-text-muted") { "Label" }
    #   p(class: "gm-text-primary fw-bold") { "Title" }
    #   small(class: "gm-text-secondary") { "Note" }
    #
    # @example Good
    #   Text(color: :muted) { "Label" }
    #   Text(level: :p, color: :primary, weight: :bold) { "Title" }
    #   Text(level: :small, color: :secondary) { "Note" }
    class NoGmTextClassOnRawHtml < Rule
      category "DesignSystem"

      # Maps CSS class name → Text atom color: argument
      TOKEN_TO_COLOR = {
        "gm-text-primary"   => ":primary",
        "gm-text-muted"     => ":muted",
        "gm-text-secondary" => ":secondary",
        "gm-text-white"     => ":light",
        "gm-text-link"      => ":link"
      }.freeze

      SEMANTIC_TOKENS = TOKEN_TO_COLOR.keys.freeze

      # Only flag raw HTML elements — design system components own their own classes
      RAW_TEXT_ELEMENTS = Set.new(%i[span p small strong em label]).freeze

      # Atoms define their own internals using raw HTML + design token classes directly.
      # Only enforce in molecules, organisms, and views.
      def self.applies_to_file?(file_path)
        !file_path.include?("/atoms/")
      end

      MESSAGE = "Use Text(color: %<color>s) instead of applying %<token>s to raw <%<element>s>. " \
                "gm-text-* classes are produced by the Text atom's color: parameter — " \
                "use the atom directly."

      def check(tree)
        tree.each_node do |node|
          next unless RAW_TEXT_ELEMENTS.include?(node.name)

          class_val = node.kwarg(:class)
          next if class_val.nil?
          next if class_val == :__dynamic__ || class_val == :__interpolated__
          next unless class_val.is_a?(String)

          tokens = class_val.split
          matched = SEMANTIC_TOKENS.find { |t| tokens.include?(t) }
          next unless matched

          violation(node, format(MESSAGE, color: TOKEN_TO_COLOR[matched], token: matched, element: node.name))
        end
      end
    end
  end
end
