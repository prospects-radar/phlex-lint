# frozen_string_literal: true

module PhlexLint
  module Rules
    # Enforce proper CSS class naming conventions.
    #
    # Classes must follow kebab-case (my-class, not myClass or My_Class).
    # No uppercase letters. Underscores are allowed in BEM notation (__element,
    # --modifier) and design tokens (gm-size-2_5rem).
    #
    # @example Bad
    #   div(class: "myWidget")
    #   p(class: "CustomText")
    #
    # @example Good
    #   div(class: "my-widget")
    #   span(class: "card__header")       # BEM element
    #   p(class: "gm-size-2_5rem")        # Design token
    class ClassNamingConvention < Rule
      category "ITCSS"

      # Pattern for invalid class names:
      #   - Contains uppercase letters (camelCase, PascalCase), OR
      #   - Contains a lone underscore (snake_case) — single `_` not part of BEM `__`.
      INVALID_PATTERN = /[A-Z]|(?<![_])_(?![_])/

      MESSAGE = "CSS class names must use kebab-case (lowercase with hyphens). " \
                "No uppercase letters. Got: %<class_name>s"

      def check(tree)
        tree.each_node do |node|
          class_val = node.kwarg(:class)
          next if class_val.nil?
          next if class_val == :__dynamic__ || class_val == :__interpolated__
          next unless class_val.is_a?(String)

          tokens = class_val.split
          invalid_tokens = tokens.select { |t| t.match?(INVALID_PATTERN) }

          next if invalid_tokens.empty?

          violation(node, format(MESSAGE, class_name: invalid_tokens.first))
        end
      end
    end
  end
end
