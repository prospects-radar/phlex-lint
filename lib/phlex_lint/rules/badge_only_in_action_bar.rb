# frozen_string_literal: true

module PhlexLint
  module Rules
    # Badge should only appear in action bars or similar tight contexts.
    #
    # Badge is a small, dense component designed for action rows and sidebars.
    # Nesting it deeply in card/section content dilutes visual hierarchy.
    #
    # @example Bad
    #   GlassCard do
    #     FlexColumn do
    #       Badge(type: :status, label: "Active")  # Too nested
    #     end
    #   end
    #
    # @example Good
    #   FlexRow do
    #     Heading(level: 3, text: "Title")
    #     Badge(type: :status, label: "Active")    # Direct sibling to heading
    #   end
    class BadgeOnlyInActionBar < Rule
      MESSAGE = "Badge should only appear at the top level of rows/bars, not deeply nested. " \
                "Badge is a dense action indicator, not content-level decoration."

      def check(tree)
        tree.each_node(:Badge) do |node|
          # Flag if Badge is more than 3 levels deep (exceeds typical action bar nesting)
          depth = count_ancestor_depth(node)
          next if depth <= 3

          violation(node, MESSAGE)
        end
      end

      private

      def count_ancestor_depth(node)
        depth = 0
        current = node
        while current.parent
          depth += 1
          current = current.parent
        end
        depth
      end
    end
  end
end
