# frozen_string_literal: true

module PhlexLint
  # Base class for all Phlex linting rules.
  #
  # Subclasses must implement `#check(tree)` and call `violation(node, message)`
  # for each detected issue.
  #
  # Subclasses may call `category "CategoryName"` to group rules for
  # qualified naming (e.g. "Structure/AlertBannerInFlexRow").
  class Rule
    attr_reader :violations

    def initialize(file_path:, parser: nil)
      @file_path = file_path
      @parser = parser
      @violations = []
    end

    # Set or get the category for this rule class.
    def self.category(value = nil)
      if value
        @category = value
      else
        @category || "Uncategorized"
      end
    end

    # Returns "Category/RuleName" for display and config matching.
    def self.qualified_name
      "#{category}/#{name.split('::').last}"
    end

    # Override to restrict this rule to specific file path patterns.
    # Return false to skip the rule for the given file.
    def self.applies_to_file?(_file_path)
      true
    end

    # Override to link to design system documentation.
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
