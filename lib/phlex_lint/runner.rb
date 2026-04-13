# frozen_string_literal: true

module PhlexLint
  # CLI runner — globs files, parses each into a PhlexNode tree, runs rules,
  # reports violations, and exits non-zero if any are found.
  class Runner
    # Run phlex-lint against all files matching `glob_pattern`.
    # Returns true when clean, false when violations are found.
    #
    # Options:
    #   components: - optional array of component name strings to restrict violations
    def self.run(glob_pattern, output: $stdout, components: nil)
      new(glob_pattern, output:, components:).run
    end

    def initialize(glob_pattern, output: $stdout, components: nil)
      @glob_pattern = glob_pattern
      @output = output
      @components = components&.map(&:to_sym)
    end

    def run
      files = Dir.glob(@glob_pattern).sort
      all_violations = []

      files.each do |file_path|
        tree = Parser.parse_file(file_path)
        next unless tree

        violations = RuleEngine.check(tree, file_path: file_path, components: @components)
        all_violations.concat(violations)
      end

      if all_violations.empty?
        @output.puts "phlex-lint: No violations found in #{files.size} file(s)."
        return true
      end

      all_violations.each { |v| @output.puts v.to_s }
      @output.puts "\nphlex-lint: #{all_violations.size} violation(s) found in #{files.size} file(s)."
      false
    end
  end
end
