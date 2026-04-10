# frozen_string_literal: true

module PhlexLint
  module Rules
    # Tabs component must contain Tab children.
    #
    # Tabs is a container for Tab components. Without them, the component is non-functional.
    #
    # @example Bad
    #   Tabs(active: "users") do
    #     div { "Content" }
    #   end
    #
    # @example Good
    #   Tabs(active: "users") do
    #     Tab(key: "users", label: "Users") { UserList() }
    #     Tab(key: "roles", label: "Roles") { RoleList() }
    #   end
    class TabsRequiresTabChildren < Rule
      category "Substitution"

      MESSAGE = "Tabs must contain at least one Tab child component."

      def check(tree)
        tree.each_node(:Tabs) do |node|
          tab_children = node.direct_children_named(:Tab)
          next unless tab_children.empty?

          violation(node, MESSAGE)
        end
      end
    end
  end
end
