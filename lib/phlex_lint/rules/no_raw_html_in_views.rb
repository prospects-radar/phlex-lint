# frozen_string_literal: true

module PhlexLint
  module Rules
    # Views must use design system atoms instead of raw HTML elements.
    #
    # Raw div/span/p/label/small in glass_morph views bypasses the design system
    # component library. Each has a proper atom equivalent with built-in theming.
    # Devise views are excluded as they use a separate styling context.
    #
    # @example Bad
    #   div(class: "my-section") { ... }
    #   span { "some text" }
    #   p { "description" }
    #
    # @example Good
    #   Section() { ... }
    #   Text() { "some text" }
    #   Paragraph() { "description" }
    class NoRawHtmlInViews < Rule
      category "Architecture"

      MESSAGES = {
        div:   "Use Section(), Box(), FlexRow(), or FlexColumn() instead of raw div.",
        span:  "Use Span() or Text() atom instead of raw span.",
        p:     "Use Paragraph() atom instead of raw p.",
        label: "Use Label() atom instead of raw label.",
        small: "Use Text(size: :sm) instead of raw small."
      }.freeze

      DEFAULT_MESSAGE = "Use a design system atom instead of raw :%<element>s."

      DETECTED_ELEMENTS = MESSAGES.keys.freeze

      def self.applies_to_file?(file_path)
        file_path.include?("app/views/glass_morph") &&
          !file_path.include?("app/views/glass_morph/devise")
      end

      def check(tree)
        DETECTED_ELEMENTS.each do |element|
          tree.each_node(element) do |node|
            message = MESSAGES.fetch(node.name) { format(DEFAULT_MESSAGE, element: node.name) }
            violation(node, message)
          end
        end
      end
    end
  end
end
