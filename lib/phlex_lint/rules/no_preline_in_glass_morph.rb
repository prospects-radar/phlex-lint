# frozen_string_literal: true

module PhlexLint
  module Rules
    # Do not use Preline components inside GlassMorph components.
    #
    # Preline and GlassMorph are separate design systems with conflicting CSS.
    # Mixing them produces broken layouts and unpredictable visual regressions.
    # Use GlassMorph atoms, molecules, and organisms exclusively within glass_morph files.
    #
    # @example Bad
    #   PrelineCard(title: "Foo") { ... }
    #   PrelineNavbar(links: [...])
    #
    # @example Good
    #   GlassCard { ... }
    #   GlassPanel { ... }
    class NoPrelineInGlassMorph < Rule
      category "Architecture"

      MESSAGE = "Do not use Preline components in GlassMorph. " \
                "Use GlassMorph atoms/molecules/organisms instead."

      def self.applies_to_file?(file_path)
        file_path.include?("app/components/glass_morph")
      end

      def check(tree)
        tree.each_node do |node|
          next unless node.name.to_s.start_with?("Preline")

          violation(node, MESSAGE)
        end
      end
    end
  end
end
