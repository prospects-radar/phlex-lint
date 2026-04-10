# frozen_string_literal: true

module PhlexLint
  module TestComponent
    # Test component for skip annotations
    class TestSkipComponent
      def view_template
        # phlex-lint:disable NoCustomClasses
        div(class: "my-widget") { "content" }

        # phlex-lint:enable NoCustomClasses
        Button(text: "Save")

        # phlex-lint:disable ButtonRequiresVariant,NoRawButtons
        button(class: "btn") { "Submit" }

        # phlex-lint:enable
        Icon(name: "search")

        # phlex-lint:disable  (disable all)
        span(class: "custom-class") { "text" }
      end
    end
  end
end
