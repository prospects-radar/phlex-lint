# frozen_string_literal: true

module PhlexLint
  module Rules
    # Organisms must compose atoms and molecules — not raw HTML elements.
    #
    # Raw HTML in organisms bypasses the design system component hierarchy,
    # producing inconsistent styling and losing accessibility attributes.
    # Table structural elements (table/thead/tbody/tr/th/td) are exempt because
    # they have no design system equivalent.
    # External link anchors with target: "_blank" are also exempt.
    #
    # @example Bad
    #   div(class: "d-flex") { ... }
    #   span(class: "fw-bold") { ... }
    #
    # @example Good
    #   FlexRow(gap: :md) { ... }
    #   Text(color: :muted) { ... }
    class NoRawHtmlInOrganisms < Rule
      category "Architecture"

      TABLE_ELEMENTS = Set.new(%i[table thead tbody tr th td]).freeze

      MESSAGE = "Organisms must compose atoms/molecules — avoid raw :%<element>s. " \
                "Use design system components."

      def self.applies_to_file?(file_path)
        file_path.include?("app/components/glass_morph/organisms")
      end

      def check(tree)
        tree.each_node do |node|
          next unless PhlexLint::Parser::RAW_HTML_ELEMENTS.include?(node.name)
          next if TABLE_ELEMENTS.include?(node.name)
          next if node.kwarg(:target) == "_blank"

          violation(node, format(MESSAGE, element: node.name))
        end
      end
    end
  end
end
