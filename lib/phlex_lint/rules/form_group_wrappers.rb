# frozen_string_literal: true

module PhlexLint
  module Rules
    # Form input components should be wrapped in FormGroup.
    #
    # FormGroup provides consistent label, error, and spacing styling for form fields.
    # Bare input components without FormGroup lack labels and error display capability.
    #
    # @example Bad
    #   Input(name: "email", type: :email)
    #
    # @example Good
    #   FormGroup(label: "Email") do
    #     Input(name: "email", type: :email)
    #   end
    class FormGroupWrappers < Rule
      category "Substitution"

      INPUT_COMPONENTS = %i[Input Select Textarea Checkbox RadioButton].freeze

      MESSAGE = "Form input components (Input, Select, Textarea, Checkbox, RadioButton) " \
                "must be wrapped in FormGroup for consistent labeling and error display."

      def check(tree)
        INPUT_COMPONENTS.each do |component_name|
          tree.each_node(component_name) do |input_node|
            # Skip if any ancestor is a FormGroup (not just direct parent,
            # since FlexRow or other layout components may sit between)
            next if ancestor?(input_node, :FormGroup)

            violation(input_node, MESSAGE)
          end
        end
      end

      private

      def ancestor?(node, name)
        current = node.parent
        while current
          return true if current.name == name
          current = current.parent
        end
        false
      end
    end
  end
end
