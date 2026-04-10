# frozen_string_literal: true

module PhlexLint
  module Rules
    # Avoid inline HTML event handler attributes (onclick, onchange, etc.).
    #
    # Inline event handlers mix behaviour into markup, are harder to test, and
    # conflict with a strict Content Security Policy. Use Stimulus controllers
    # with data-action attributes instead.
    #
    # @example Bad
    #   button(onclick: "doSomething()")
    #   input(onchange: "handleChange(this)")
    #
    # @example Good
    #   button(data: { controller: "my-feature", action: "click->my-feature#doSomething" })
    class NoInlineEventHandlers < Rule
      category "Style"

      EVENT_ATTRS = %i[onclick onchange onsubmit onkeyup onkeydown onmousedown onmouseup onfocus onblur].freeze
      MESSAGE = "Avoid inline event handlers (%<attr>s). Use Stimulus controllers instead."

      def check(tree)
        tree.each_node do |node|
          found_attr = EVENT_ATTRS.find { |attr| node.kwargs.key?(attr) }
          next unless found_attr

          violation(node, format(MESSAGE, attr: found_attr))
        end
      end
    end
  end
end
