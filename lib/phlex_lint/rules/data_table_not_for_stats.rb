# frozen_string_literal: true

module PhlexLint
  module Rules
    # StatCard and DataCard should not appear inside DataTable.
    #
    # StatCard and DataCard are metric/summary cards designed for dashboards.
    # They don't belong in a tabular data display. Use DataTable for structured data.
    #
    # @example Bad
    #   DataTable(columns: [...]) do
    #     StatCard(label: "Count", value: "100")  # Wrong component
    #   end
    #
    # @example Good
    #   FlexRow do
    #     StatCard(label: "Count", value: "100")
    #     StatCard(label: "Total", value: "500")
    #   end
    class DataTableNotForStats < Rule
      category "Substitution"

      MESSAGE = "StatCard/DataCard should not appear inside DataTable. Use for dashboards only. " \
                "Use DataTable rows for tabular display instead."

      def check(tree)
        tree.each_node(:DataTable) do |table_node|
          %i[StatCard DataCard].each do |component_name|
            table_node.each_node(component_name) do |card_node|
              violation(card_node, MESSAGE)
            end
          end
        end
      end
    end
  end
end
