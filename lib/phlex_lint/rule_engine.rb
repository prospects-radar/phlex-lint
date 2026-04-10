# frozen_string_literal: true

module PhlexLint
  # Runs all registered rules against a PhlexNode tree and returns violations.
  class RuleEngine
    RULES = PhlexLint::Rules.constants
                            .map { |c| PhlexLint::Rules.const_get(c) }
                            .select { |c| c.is_a?(Class) && c < PhlexLint::Rule }
                            .freeze

    # Run all (or filtered) rules against the tree and return an array of Violations.
    #
    # Options:
    #   file_path: - the file being checked (used for per-rule file filtering)
    #   only:      - optional array of rule short names to restrict checking
    #   parser:    - optional Parser instance (used for skip annotation support)
    #   config:    - optional Configuration instance (used for per-rule enable/disable)
    def self.check(tree, file_path:, only: nil, parser: nil, config: nil)
      violations = []

      RULES.each do |rule_class|
        short_name = rule_class.name.split("::").last

        # --only filter: accept short name (e.g. "NoRawButtons") or qualified name (e.g. "DesignSystem/NoRawButtons")
        next if only && !only.include?(short_name) && !only.include?(rule_class.qualified_name)

        # Per-rule file applicability
        next unless rule_class.applies_to_file?(file_path)

        # Configuration-based filtering
        if config && !config.empty?
          next unless config.applies_to_file?(rule_class.qualified_name, file_path)
        end

        rule = rule_class.new(file_path: file_path, parser: parser)
        rule.check(tree)
        violations.concat(rule.violations)
      end

      violations
    end
  end
end
