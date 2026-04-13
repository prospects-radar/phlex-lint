# frozen_string_literal: true

module PhlexLint
  module Rules
    # Component calls must not receive custom classes directly.
    #
    # Phlex component calls are already semantic. Passing a class kwarg directly to the
    # component makes it impossible to distinguish component API usage from ad hoc styling
    # and hides whether the styling belongs on a wrapper or should be exposed as an
    # explicit parameter.
    #
    # @example Bad
    #   Heading(level: 2, class: "hero-title") { "Title" }
    #   Text(class: computed_class) { "Body" }
    #   Button(variant: :primary, class: "ms-3") { "Save" }
    #
    # @example Good
    #   Heading(level: 2, color: :primary) { "Title" }
    #   Text(color: :muted) { "Body" }
    #   Button(variant: :primary) { "Save" }
    class NoExtraClassesOnStandardizedComponents < Rule
      category "Architecture"

      # Atoms define their own internals and are allowed to use Bootstrap utilities
      # on sub-components. Only enforce this rule in higher-level components and views.
      def self.applies_to_file?(file_path)
        !file_path.include?("/atoms/")
      end

      MESSAGE = "Remove class from %<component>s — components must use explicit parameters or a wrapper element instead."

      def check(tree)
        tree.each_node do |node|
          class_val = node.kwarg(:class)
          next if class_val.nil?

          violation(node, format(MESSAGE, component: node.name))
        end
      end
    end
  end
end
