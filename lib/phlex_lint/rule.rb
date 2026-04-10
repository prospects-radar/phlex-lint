# frozen_string_literal: true

module PhlexLint
  # Base class for all Phlex linting rules.
  #
  # Subclasses must implement `#check(tree)` and call `violation(node, message)`
  # for each detected issue.
  #
  # Subclasses may override `.applies_to_file?` to restrict the rule to a subset
  # of files (e.g. only `app/components/settings/**`).
  #
  # Subclasses may override `.documentation_url` to provide a link to the
  # design system skill or guide that explains the rule.
  class Rule
    attr_reader :violations

    def initialize(file_path:, parser: nil)
      @file_path = file_path
      @parser = parser
      @violations = []
    end

    # Declare this rule's category. Used to build the qualified name
    # (e.g., "Style/NoInlineStyles") shown in violation output and config.
    #
    #   class NoInlineStyles < Rule
    #     category "Style"
    #   end
    #
    # Call without arguments to read: `NoInlineStyles.category # => "Style"`
    def self.category(name = nil)
      if name
        @category = name.to_s.freeze
      else
        @category
      end
    end

    # Returns "Category/RuleName" (e.g., "Style/NoInlineStyles").
    # Falls back to just "RuleName" if no category is set.
    def self.qualified_name
      short = name.split("::").last
      cat = category
      cat ? "#{cat}/#{short}" : short
    end

    # Returns just "RuleName" without category prefix.
    def self.short_name
      name.split("::").last
    end

    # Override to restrict this rule to specific file path patterns.
    # Return false to skip the rule for the given file.
    def self.applies_to_file?(_file_path)
      true
    end

    # Override to link to design system documentation.
    # Return a skill path (e.g. ".claude/skills/design-system/SKILL.md#component-decision-tree")
    # or external URL.
    def self.documentation_url
      nil
    end

    # Subclasses implement this to inspect the tree and call violation().
    def check(_tree)
      raise NotImplementedError, "#{self.class}#check must be implemented"
    end

    protected

    # Override in subclasses to provide an auto-correction for this violation.
    # Return a Correction object, or nil if not auto-correctable.
    # Has access to @file_path.
    def auto_correct(_node, _message)
      nil
    end

    def violation(node, message)
      correction = auto_correct(node, message)
      @violations << Violation.new(
        node: node,
        message: message,
        file_path: @file_path,
        rule_class: self.class,
        correction: correction,
        parser: @parser
      )
    end
  end
end
