# frozen_string_literal: true

module PhlexLint
  module Rules
    # Settings pages must use ConfigurationCard for form sections, not raw GlassCard.
    #
    # ConfigurationCard provides the correct padding, title styling, and section semantics
    # for settings pages. Using GlassCard(variant: :section) directly breaks the settings layout pattern.
    #
    # This rule applies only to app/components/settings/** and app/views/glass_morph/settings/**.
    #
    # @example Bad
    #   GlassCard(variant: :section, title: "Email Settings") do
    #     FormGroup(...)
    #   end
    #
    # @example Good
    #   ConfigurationCard(title: "Email Settings") do
    #     FormGroup(...)
    #   end
    class ConfigCardInSettings < Rule
      category "Substitution"

      FILE_PATTERN_COMPONENTS = "app/components/settings/**/*.rb"
      FILE_PATTERN_VIEWS = "app/views/glass_morph/settings/**/*.rb"

      MESSAGE = "Settings form sections must use ConfigurationCard, not GlassCard(variant: :section). " \
                "ConfigurationCard provides correct padding and section semantics."

      def self.applies_to_file?(file_path)
        File.fnmatch(FILE_PATTERN_COMPONENTS, file_path, File::FNM_PATHNAME) ||
          File.fnmatch(FILE_PATTERN_VIEWS, file_path, File::FNM_PATHNAME)
      end

      def check(tree)
        return unless self.class.applies_to_file?(@file_path)

        tree.each_node(:GlassCard) do |node|
          next unless node.kwarg(:variant) == :section

          violation(node, MESSAGE)
        end
      end
    end
  end
end
