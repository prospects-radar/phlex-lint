# frozen_string_literal: true

module PhlexLint
  module Rules
    # Settings page view_template must use PageContainer as the outermost wrapper.
    #
    # PageContainer provides the `.page-inner` CSS context that PageHeader requires
    # for its teal gradient styling. Without it, PageHeader renders as plain text.
    #
    # This rule applies only to files under app/components/settings/.
    #
    # @example Bad — first element is FlexColumn or GlassCard
    #   def view_template
    #     FlexColumn(gap: :lg) do
    #       PageHeader(...)
    #     end
    #   end
    #
    # @example Good
    #   def view_template
    #     PageContainer(**tid("...")) do
    #       PageHeader(...)
    #     end
    #   end
    class SettingsPageUsesPageContainer < Rule
      category "Structure"

      FILE_PATTERN = "app/components/settings/**/*.rb"
      MESSAGE = "Settings page view_template must use PageContainer as the outermost wrapper " \
                "(required for PageHeader gradient styling). Found: %<found>s"

      def self.documentation_url
        ".claude/skills/design-system/references/page-templates.md#settings"
      end

      def self.applies_to_file?(file_path)
        File.fnmatch(FILE_PATTERN, file_path, File::FNM_PATHNAME)
      end

      def check(tree)
        return unless self.class.applies_to_file?(@file_path)
        return if tree.children.empty?

        first_child = tree.children.first
        return if first_child.name == :PageContainer

        violation(first_child, format(MESSAGE, found: first_child.name))
      end
    end
  end
end
