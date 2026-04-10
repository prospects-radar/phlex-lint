# frozen_string_literal: true

module PhlexLint
  module Rules
    # Use data: keyword instead of deprecated data attribute parameters.
    #
    # The parameters additional_data_attrs: and data_attributes: are deprecated.
    # Use the standard data: keyword argument instead.
    #
    # @example Bad
    #   Button(text: "Save", additional_data_attrs: { controller: "form" })
    #   Modal(id: "confirm", data_attributes: { action: "click->modal#open" })
    #
    # @example Good
    #   Button(text: "Save", data: { controller: "form" })
    #   Modal(id: "confirm", data: { action: "click->modal#open" })
    class DataParameter < Rule
      category "ComponentAPI"

      MESSAGE = "Use data: keyword instead of deprecated %<param>s parameter."

      DEPRECATED_PARAMS = %i[additional_data_attrs data_attributes].freeze

      def check(tree)
        tree.each_node do |node|
          DEPRECATED_PARAMS.each do |param|
            next unless node.kwargs.key?(param)

            violation(node, format(MESSAGE, param: param))
          end
        end
      end
    end
  end
end
